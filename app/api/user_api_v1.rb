require 'grape'
require 'json'

class UserAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
  formatter :json, SuccessFormatter
  format :json
  default_format :json
  content_type :json, "application/json"
  version 'v1', :using => :path, :format => :json

  helpers RecurlyHelper
  helpers AwsHelper


  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :users do
    desc "Register a new user. "
    params do
      requires :name, :type => String, :desc => "Username, would be used for sign in"
      requires :email, :type => String#,:validate_email_format => true,  :desc => "Email"
      requires :password, :type => String, :desc => "Password"
      requires :password_confirmation, :type => String, :desc => "Confirm Password"
    end
    post "register"  do
      user = User.new
      
      user.name = params[:name]
      user.email = params[:email]
      user.password = params[:password]
      user.password_confirmation = params[:password_confirmation]
      user.save!

      user.reset_authentication_token!
      
      status 200
      {
        :id => user.id,
        :name => user.name,
        :email => user.email,
        :authentication_token => user.authentication_token
      }
    end

    desc "Get authentication_token."
     params do
      requires :login, :type => String,  :desc => "Username or email"
      requires :password, :type => String, :desc => "Password"
    end
    get "authentication_token" do
      is_valid = false
      
      user = User.find_by_email(params[:login])
      
      if user 
        is_valid = user.valid_password?(params[:password])
      else
        user = User.find_by_name(params[:login])
        is_valid = user.valid_password?(params[:password]) if user
      end
      
      if is_valid 
        {
          :authentication_token => user.authentication_token
        }
      else
        access_denied!
      end
    end   
 
   desc "Get current logged in user. "
    get "me" do
      authenticated_user

      present current_user, with: User::Entity
    end


    desc "Update user information. "
  params do    
    optional :email, :type => String, :desc => "User email"
  end
  put 'me' do
    authenticated_user

    user = current_user
    user.updating_password = false    
    user.email = params[:email] if params[:email]

    status 200
    Audit.as_user(current_user) do  
      user.save!
    end 
    
    present current_user
  end

  desc "Change password for current user. "
  params do
    optional :password, :type => String, :desc => "Password"
    optional :password_confirmation, :type => String, :desc => "Password"
  end
  put 'me/change_password' do
    authenticated_user

    user = current_user
    user.updating_password = true


    user.password = params[:password] if params[:password]
    user.password_confirmation = params[:password_confirmation] if params[:password_confirmation]
    status 200

    user.save!
    user.reset_authentication_token!
    present user
  end

  desc "Check if reset passord is valid or not.If valid return user details. "
  params do
    requires :reset_password_token, :type => String, :desc => "Reset password token"
  end
  get 'find_by_password_token' do
    reset_password_token = Devise.token_generator.digest(User, :reset_password_token, params[:reset_password_token])
    user = User.where(reset_password_token: reset_password_token).first
    status 200
    invalid_request!(INVALID_TOKEN, "Token already used or is invalid") unless user
    invalid_request!(INVALID_TOKEN, "Token expired") unless user.reset_password_period_valid?
    present user
  end

  desc "Change password using reset_password_token. "
  params do
    requires :password, :type => String, :desc => "Password"
    requires :password_confirmation, :type => String, :desc => "Password"
    requires :reset_password_token, :type => String, :desc => "Reset password token"
  end
  post 'reset_password' do
    reset_password_token = Devise.token_generator.digest(User, :reset_password_token, params[:reset_password_token])
    user = User.where(reset_password_token: reset_password_token).first
    invalid_request!(INVALID_TOKEN, "Token already used or is invalid") unless user
    invalid_request!(INVALID_TOKEN, "Token expired") unless user.reset_password_period_valid?

    result = user.reset_password!(params[:password], params[:password_confirmation])
    status 200
    
    if result
      user.reset_authentication_token!
      "Password changed successfully"
    else
      "Password doesn't match confirmation" 
    end   
   
  end


    ###############################################################################################################################
    # Admin queries
    ###############################################################################################################################
    desc "Get list of all users. (Admin access needed) "
    params do
    optional :q, :type => Hash, :desc => "Search parameter"
    optional :page, :type => Integer
    optional :size, :type => Integer
  end

    get   do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, User)
      
      search_result = User.search(params[:q])
      users = params[:q] ? search_result.result(distinct: true) : User
      
      present users.paginate(:page => params[:page], :per_page => params[:size]) , with: User::Entity
    end

    desc "Get a specific user. (Admin access needed) "
    get ':id'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, User)
      user = User.where(id: params[:id]).first
      not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user

      present user, with: User::Entity
    end

    desc "Delete specified user. (Admin access needed) "
     params do
      requires :comment, :type => String, :desc => "Comment"
    end
    delete  ':id'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:destroy, User)
      user = User.where(id: params[:id]).first
      not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user


      if user.role == "admin"  # Keep one admin
        bad_request!(INVALID_REQUEST, "One admin should be present") if User.where(role: 1).count == 1
      elsif user.role == "wowza_user"
        bad_request!(INVALID_REQUEST, "One wowza user should be present") if User.where(role: 4).count == 1  
      end

      user.audit_comment = params[:comment]
      ActiveRecord::Base.transaction do
        Audit.as_user(current_user) do 
          user.destroy
        end

       DeviceInvitation.where(shared_with: user.email).destroy_all
       SharedDevice.where(shared_with: user.id).destroy_all 
      end

      status 200
      "User deleted!"
    end

    desc "Send reset password mail"  
     params do
      requires :login, :type => String,  :desc => "Username or email"
    end   
    post 'forgot_password' do  #check 1

      user = User.where(name: params[:login]).first
      user = User.where(email: params[:login]).first unless user
      not_found!(USER_NOT_FOUND, "User: " + params[:login].to_s) unless user
      status 200 
          Thread.new {
          user.send_reset_password_instructions
          } 
          "Sending reset password email"
    end

    desc "Get audits related to a specific user "
    get ':id/audit'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, User)

      user = User.with_deleted.where(id: params[:id]).first
      not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user

      status 200
      {
        "user_audits" => user.audits,
       "user_associated_audits" => user.associated_audits
     }


    end

    desc "send custom notification to one or more users. "
    params do
      requires :user_ids,:desc => "Comma seperated user ids"
      requires :message, :type => String, :desc => "Notification message"
    end
    post 'notify'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, User)
      status 200
      user_ids = params[:user_ids].split(',')
      
       user_ids.each do |id|
       
          user = User.where(id: id).first
          batch_notification(user,params[:message]) if user
       end 

       "Notification send"
    end

    desc "Register a user through Facebook"
      params do
      requires :access_token, :type => String,  :desc => "Enter the access token."
      requires :email, :type => String, :desc => "Enter the email id."
      end

      post "login_with_facebook" do
        client = FBGraph::Client.new(:client_id => Settings.facebook_app_id,:secret_id => Settings.facebook_app_secret,:token => params[:access_token])
        begin
         info = client.selection.me.info!
          rescue RestClient::BadRequest
          bad_request!(INVALID_DEVICE_TOKEN, "Invalid parameter: Access token is invaild.")
        end
        user = User.where(email: params[:email]).first
        unless user
          user = User.new
          user.name = info.name
          user.email = params[:email]
          create_password = Devise.friendly_token[0,20]
          user.password = create_password
          user.password_confirmation = create_password
          user.save!
          user.reset_authentication_token!
        end
         
        status 200
        {
        :facebook_id => info.id.to_i,
        :id => user.id,
        :name => info.name,
        :email => user.email,
        :authentication_token => user.authentication_token
        }
       end 
   


    
  end
    
end