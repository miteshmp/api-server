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
  helpers OmniauthHelper


  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :users do

    # Query :- Register a new User
    # Method :- POST
    # Parameters :-
    #         name  :- User name ( Must be unique )
    #         email :- User email ( Must be unique )
    #         password :- User password ( Length must be 8 character )
    #         password_confirmation :- Re type password
    # Response :-
    #         Return User information

    desc "Register a new User."

    params do

      requires :name,   :type => String,  :desc => "Username, would be used for sign in"
      requires :email,  :type => String,  :desc => "User email address" #,:validate_email_format => true,  :desc => "Email"
      requires :password, :type => String,  :desc => "Password"
      requires :password_confirmation,  :type => String,  :desc => "Confirm Password"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

    end

    post "register"  do

      user = User.new

      user.name = params[:name]
      user.email = params[:email]
      user.password = params[:password]
      user.password_confirmation = params[:password_confirmation]
      user.tenant_id = params[:tenant_id] if params[:tenant_id].present?
      user.save!

      user.reset_authentication_token!
      create_recurly_account(user)
      status 200
      {
        :id => user.id,
        :name => user.name,
        :email => user.email,
        :authentication_token => user.authentication_token
      }

    end
    # Completed Register User Query

    # Method :- POST
    # Parameters :-
    #         login :- User name / Email
    #         password :- User password
    # Response :-
    #         Return User authentication token if valid user.
    desc "Get authentication_token."

    params do

      requires :login,    :type => String,  :desc => "Username or email"
      requires :password, :type => String, :desc => "Password"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post "authentication_token" do

      is_valid = false

      # Fetch authentication token & password information from database.
      # Search User record using email address
      user = User.select("authentication_token,encrypted_password").find_by_email(params[:login])

      if user

        # devise gem provides method to validate password.
        is_valid = user.valid_password?(params[:password])

      else

        # Search User record using "name" field
        user = User.select("authentication_token,encrypted_password").find_by_name(params[:login])
        is_valid = user.valid_password?(params[:password]) if user

      end

      if is_valid
        {
          :authentication_token => user.authentication_token
        }
      else
        # Access denied :- Invalid login information provided.
        access_denied!
      end

    end
    # Complete Query :- Login API

    # Query :- Get Current User information
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return current logged user information

    # ToDo :- avoid two time database operation
    desc "Get current logged in user. "
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

    get "me" do

      # check user account information & return active user object.
      active_user = authenticated_user

      if active_user

        # return active user information
        present active_user, with: User::Entity, type: :full
      else

        access_denied!

      end
    end
    # Complete Query :- Get Current User Information

    # Query :- Update Current User information
    # Method :- PUT
    # Parameters :-
    #         email :- Update user's email address
    # Response :-
    #         Return current logged user information
    desc "Update user information."

    params do
      requires :password, :type => String, :desc => "Password"
      optional :email, :type => String, :desc => "User email"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    route [:put, :post], "me" do

      # check user account information & return active user object.
      active_user = authenticated_user

      if ( active_user && active_user.valid_password?(params[:password]))
        # check that active user existed or not.

        active_user.updating_password = false
        active_user.email = params[:email] if params[:email]

        status 200
        Audit.as_user(active_user) do
          active_user.save!
        end

        present active_user

      else
        # access denied if user is not existed.
        access_denied!

      end

    end
    # Complete Query :- Update Current User information

    # Admin Query :- Delete a current user
    # Method :- DELETE
    # Parameters :-
    #         comment :- comment for deleting  current user
    # Response :-
    #         Return message "user deleted" if get sucess.
    desc "Delete current user."

    params do
      requires :comment, :type => String, :desc => "Comment"
    end

    delete  'me'  do

      active_user = authenticated_user ;

      admins = User.with_role :admin ;
      wowza_users = User.with_role :wowza_user ;
      bp_server = User.with_role :bp_server ;
      talkback_users = User.with_role :talk_back_user ;
      uploadServer_users = User.with_role :upload_server ;

      if active_user.is? :admin  # Keep one admin
        bad_request!(INVALID_REQUEST, "One admin should be present") if admins.count == 1

      elsif active_user.is? :wowza_user
        bad_request!(INVALID_REQUEST, "One wowza user should be present") if wowza_users.count == 1

      elsif active_user.is? :bp_server
        bad_request!(INVALID_REQUEST, "One bp server user should be present") if bp_server.count == 1

      elsif active_user.is? :talk_back_user
        bad_request!(INVALID_REQUEST, "One talk back server user should be present") if talkback_users.count == 1

      elsif active_user.is? :upload_server
        bad_request!(INVALID_REQUEST, "One upload server user should be present") if uploadServer_users.count == 1

      end

      active_user.audit_comment = params[:comment]

      ActiveRecord::Base.transaction do

        Audit.as_user(active_user) do

          active_user.destroy
        end

        DeviceInvitation.where(shared_with: active_user.email).destroy_all
        SharedDevice.where(shared_with: active_user.id).destroy_all

      end

      status 200
      "User deleted!"
    end
    # Complete Admin Query :- Delete specific user

    # Query :- Change password for current User
    # Method :- PUT
    # Parameters :-
    #         password :- new password
    #         password_confirmation :- re-type password
    # Response :-
    #         Return current logged user information

    # Todo :- Invalid response message if parameter missings
    desc "Change password for current user. "

      params do
        requires :current_password, :type => String, :desc => "Current Password"
        requires :password, :type => String, :desc => "New Password"
        requires :password_confirmation, :type => String, :desc => "New Password Confirmation"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      route [:put, :post], 'me/change_password' do

        # check user account information & return active user object.
        active_user = authenticated_user
        authorized_user = false ;

      if params[:current_password]

        authorized_user = active_user.valid_password?(params[:current_password]) ;
      end

      if authorized_user

        active_user.updating_password = true

        active_user.password = params[:password] if params[:password]
        active_user.password_confirmation = params[:password_confirmation] if params[:password_confirmation]

        status 200

        active_user.save!
        active_user.reset_authentication_token!

        # Send change password notification to User
        send_notification(active_user,nil,EventType::RESET_PASSWORD_EVENT.to_s,get_user_agent);

        present active_user

      else

        # access denied if user is not existed.
        access_denied!
      end

    end
    # Complete Query :- Change password for current user

    # Query :- Check that reset password token is valid.
    # Method :- GET
    # Parameters :-
    #         reset_password_token :- Reset password token
    # Response :-
    #         Return current logged user information

    desc "Check if reset passord is valid or not.If valid return user details. "

    params do

      requires :reset_password_token, :type => String, :desc => "Reset password token"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    get 'find_by_password_token' do

      reset_password_token = Devise.token_generator.digest(User, :reset_password_token, params[:reset_password_token])

      active_user = User.where(reset_password_token: reset_password_token).first

      status 200
      invalid_request!(INVALID_TOKEN, "Token already used or is invalid") unless active_user
      invalid_request!(INVALID_TOKEN, "Token expired") unless active_user.reset_password_period_valid?

      present active_user
    end
    # Complete Query :- check that reset password token is valid.

    # Query :- Change password using reset password token.
    # Method :- POST
    # Parameters :-
    #         password :- new password
    #         password_confirmation :- new retype password
    #         reset_password_token :- Reset password token
    # Response :-
    #         Return current logged user information
    desc "Change password using reset_password_token. "

    params do

      requires :password, :type => String, :desc => "Password"
      requires :password_confirmation, :type => String, :desc => "Password"
      requires :reset_password_token, :type => String, :desc => "Reset password token"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post 'reset_password' do

      reset_password_token = Devise.token_generator.digest(User, :reset_password_token, params[:reset_password_token])

      active_user = User.where(reset_password_token: reset_password_token).first
      invalid_request!(INVALID_TOKEN, "Token already used or is invalid") unless active_user
      invalid_request!(INVALID_TOKEN, "Token expired") unless active_user.reset_password_period_valid?

      result = active_user.reset_password!(params[:password], params[:password_confirmation])
      status 200

      active_user.password = params[:password] if params[:password]
      active_user.password_confirmation = params[:password_confirmation] if params[:password_confirmation]
      active_user.clear_reset_password_token
      active_user.save!
      active_user.reset_authentication_token! ;

      # Send change password notification to User
      send_notification(active_user,nil,EventType::RESET_PASSWORD_EVENT.to_s,get_user_agent);

      "Password changed successfully"
    end

    desc "Get a list of subscriptions that belong to a user"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end
    get 'subscriptions' do
      active_user = authenticated_user
      user_plans = active_user.user_subscriptions.select("plan_id, user_id, subscription_source, subscription_uuid, state, expires_at").all
      recurly_account = get_account(active_user.id)
      if recurly_account.present?
        hosted_login_token = recurly_account.hosted_login_token
      end
      status 200
      {
        "plans" => user_plans,
        "recurly_account_token" => hosted_login_token
      }
    end

    desc "Create a new recurly paid subscription"
    params do
      requires :plan_id, :type => String, :desc => "Name of the plan"
      optional :recurly_secret, :type => String, :desc => "Secret token returned by Recurly"
      optional :currency_unit, :type => String, :desc => "The ISO currency unit to be used for charging the subscription. By default, the plan's currency unit would be used."
      optional :recurly_coupon, :type => String, :desc => "Recurly coupon to be used for the subscription"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    post 'subscriptions' do
      active_user = authenticated_user
      plan = SubscriptionPlan.where(plan_id: params[:plan_id]).first()
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:plan_id].to_s) unless plan
      if (params[:currency_unit].blank?)
        params[:currency_unit] = plan.currency_unit
      end
      current_subscription = active_user.user_subscriptions.where('state != ?', RECURLY_SUBSCRIPTION_STATE_EXPIRED).first
      if current_subscription.present? 
        bad_request!(400, "A subscription already exists for the user!")  
      end
      begin
        user_subscription = UserSubscription.new
        user_subscription.plan_id = params[:plan_id]
        user_subscription.subscription_plan_id = plan.id
        user_subscription.user_id = active_user.id
        user_subscription.subscription_source = "recurly"
        subscription = user_subscription.create_recurly_subscription(params[:recurly_coupon], params[:recurly_secret], params[:currency_unit], active_user)

        DeviceFreeTrial.where(user_id: active_user.id).update_all(status: FREE_TRIAL_STATUS_EXPIRED)
        get_subscription_data(subscription)
      rescue Recurly::Resource::NotFound => e
        bad_request!(ERROR_RECURLY_ACCOUNT_NOT_FOUND, e.message)
      rescue Recurly::API::UnprocessableEntity => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)
      rescue Recurly::API::NotFound => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)  
      end
    end

    desc "Get a user's billing info from recurly"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end
    get "subscriptions/billing_info" do
      active_user = authenticated_user
      begin
        get_recurly_billing(active_user.id).attributes
      rescue Recurly::Resource::NotFound => e
        bad_request!(ERROR_RECURLY_ACCOUNT_NOT_FOUND, e.message)
      end
    end

    desc "Update a user's billing info in recurly"
    params do
      requires :recurly_secret, :type => String, :desc => "Secret token returned by Recurly"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    put "subscriptions/billing_info" do
      active_user = authenticated_user
      begin
        subscription = update_recurly_account(active_user.id, params[:recurly_secret])
        status 200
      rescue Recurly::Resource::NotFound => e
        bad_request!(ERROR_RECURLY_ACCOUNT_NOT_FOUND, e.message)
      rescue Recurly::API::UnprocessableEntity => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)
      rescue Recurly::API::NotFound => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)  
      end
    end

    desc "Update a user's recurly subscription"
    params do
      requires :plan_id, :type => String, :desc => "Name of the plan"
      optional :devices_registration_id, :type => Array, :desc => "The list of registration_id of the devices that need to be updated"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    put "subscriptions/:subscription_uuid" do
      active_user = authenticated_user
      user_subscription = UserSubscription.where(subscription_uuid: params[:subscription_uuid], user_id: active_user.id).first()
      not_found!(ERROR_RECURLY_SUBSCRIPTION_NOT_FOUND, "Subscription uuid: " + params[:subscription_uuid].to_s) unless user_subscription
      plan = SubscriptionPlan.where(plan_id: params[:plan_id]).first()
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:plan_id].to_s) unless plan
      if (user_subscription.state == RECURLY_SUBSCRIPTION_STATE_CANCELED)
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, "A canceled subscription: #{params[:subscription_uuid]} cannot be updated!")
      end
      begin
        subscription = user_subscription.change_recurly_subscription(plan, false, params[:devices_registration_id], active_user)
        get_subscription_data(subscription)
      rescue Recurly::Resource::NotFound => e
        bad_request!(ERROR_RECURLY_ACCOUNT_NOT_FOUND, e.message)
      rescue Recurly::API::UnprocessableEntity => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)
      rescue Recurly::API::NotFound => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)  
      end
    end

    desc "Reactivate a user's recurly subscription"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end
    put "subscriptions/:subscription_uuid/reactivate" do
      active_user = authenticated_user
      user_subscription = UserSubscription.where(subscription_uuid: params[:subscription_uuid], user_id: active_user.id).first()
      not_found!(ERROR_RECURLY_SUBSCRIPTION_NOT_FOUND, "Subscription uuid: " + params[:subscription_uuid].to_s) unless user_subscription
      if (user_subscription.state != RECURLY_SUBSCRIPTION_STATE_CANCELED)
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, "A subscription with state: #{user_subscription.state} cannot be reactivated!")
      end
      begin
        subscription = user_subscription.reactivate_recurly_subscription(params[:subscription_uuid])
        get_subscription_data(subscription)
      rescue Recurly::Resource::NotFound => e
        bad_request!(ERROR_RECURLY_ACCOUNT_NOT_FOUND, e.message)
      rescue Recurly::API::UnprocessableEntity => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)
      rescue Recurly::API::NotFound => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)  
      end
    end

    desc "Cancel a user's recurly subscription"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end
    put "subscriptions/:subscription_uuid/cancel" do
      active_user = authenticated_user
      user_subscription = UserSubscription.where(subscription_uuid: params[:subscription_uuid], user_id: active_user.id).first()
      not_found!(ERROR_RECURLY_SUBSCRIPTION_NOT_FOUND, "Subscription uuid: " + params[:subscription_uuid].to_s) unless user_subscription
      begin
        subscription = user_subscription.change_recurly_subscription(nil, true, [], active_user)
        get_subscription_data(subscription)
      rescue Recurly::Resource::NotFound => e
        bad_request!(ERROR_RECURLY_ACCOUNT_NOT_FOUND, e.message)
      rescue Recurly::API::UnprocessableEntity => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)
      rescue Recurly::API::NotFound => e
        bad_request!(ERROR_RECURLY_SUBSCRIPTION, e.message)  
      end
    end

    # Complete Query :- Change password using reset authentication token

    ###############################################################################################################################
    # Admin queries
    ###############################################################################################################################

    # Admin Query :- Get List of all Users.
    # Method :- GET
    # Parameters :-
    #         q :- new Search parameter
    #         page :- page number
    #         size :- size of each page
    # Response :-
    #         Return user information based on search parameter
    desc "Get list of all users. (Admin access needed) "

    params do

      optional :q, :type => Hash, :desc => "Search parameter"
      optional :page, :type => Integer
      optional :size, :type => Integer

    end

    get   do

      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:read_any, User)

      if params[:q]

        # check that q parameter is present & search results based on parameter.
        search_result = User.search(params[:q])
        users = params[:q] ? search_result.result(distinct: true) : User

      else

        # Return all users ( No search parameter availble)
        users = User

      end

      present users.paginate(:page => params[:page], :per_page => params[:size]) , with: User::Entity, type: :full

    end
    # Complete Admin Query :- Get List of all Users


    # Admin Query :- Get a specific user detail
    # Method :- GET
    # Parameters :-
    #         q :- new Search parameter
    #         page :- page number
    #         size :- size of each page
    # Response :-
    #         Return user information based on search parameter
    desc "Get a specific user. (Admin access needed) "
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

    get ':id'  do

      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:read_any, User)

      user = User.where(id: params[:id]).first
      not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user

      present user, with: User::Entity, type: :full

    end
    # Complete Admin Query :- Get a specific user

    # Admin Query :- Delete a specific user
    # Method :- DELETE
    # Parameters :-
    #         comment :- comment for deleting user
    # Response :-
    #         Return message "user deleted" if get sucess.
    desc "Delete specified user. (Admin access needed) "

    params do

      requires :comment, :type => String, :desc => "Comment"
    end

    delete  ':id'  do

      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:destroy, User)

      user = User.where(id: params[:id]).first
      not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user

      admins = User.with_role :admin
      wowza_users = User.with_role :wowza_user
      bp_server = User.with_role :bp_server
      talkback_users = User.with_role :talk_back_user
      uploadServer_users = User.with_role :upload_server

      if user.is? :admin  # Keep one admin
        bad_request!(INVALID_REQUEST, "One admin should be present") if admins.count == 1
      elsif user.is? :wowza_user
        bad_request!(INVALID_REQUEST, "One wowza user should be present") if wowza_users.count == 1
      elsif user.is? :bp_server
        bad_request!(INVALID_REQUEST, "One bp server user should be present") if bp_server.count == 1
      elsif user.is? :talk_back_user
        bad_request!(INVALID_REQUEST, "One talk back server user should be present") if talkback_users.count == 1
      elsif user.is? :upload_server
        bad_request!(INVALID_REQUEST, "One upload server user should be present") if uploadServer_users.count == 1
      end

      user.audit_comment = params[:comment]

      ActiveRecord::Base.transaction do

        Audit.as_user(user) do

          user.destroy
        end

        DeviceInvitation.where(shared_with: user.email).destroy_all
        SharedDevice.where(shared_with: user.id).destroy_all

      end

      status 200
      "User deleted!"
    end
    # Complete Admin Query :- Delete specific user

    # Query :- Send Reset password on Mail
    # Method :- POST
    # Parameters :-
    #         login :- Provide user name or Email address
    # Response :-
    #         Return message "user deleted" if get sucess.
    desc "Send reset password mail"

    params do

      requires :login, :type => String,  :desc => "Username or email"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post 'forgot_password' do  #check 1

      user = User.where(name: params[:login]).first
      user = User.where(email: params[:login]).first unless user
      not_found!(USER_NOT_FOUND, "User: " + params[:login].to_s) unless user

      status 200

      Thread.new {

        begin
          user.send_reset_password_instructions
        rescue Exception => exception
          Rails.logger.warn("caught exception ==> #{exception}")
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end

      }
      "Sending reset password email"
    end
    # Complete Query :- Send Reset Password Email

    # Admin Query :- Get Audit related to specific User
    # Method :- GET
    # Parameters :-
    #         id :- User ID
    # Response :-
    #         Return message "user deleted" if get sucess.
    desc "Get audits related to a specific user ( Admin access) "
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

    get ':id/audit'  do

      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:read_any, User)

      user = User.with_deleted.where(id: params[:id]).first
      not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user

      status 200
      {
        "user_audits" => user.audits,
        "user_associated_audits" => user.associated_audits
      }

    end
    # Complete Admin Query :- Send reset password email

    # Admin Query :- Send Custom Notification to users
    # Method :- POST
    # Parameters :-
    #         user id :- Provide different user ID
    #         message :- Notification Message
    # Response :-
    #         Send custom notification to all users.
    desc "send custom notification to one or more users. "

    params do

      requires :user_ids,:desc => "Comma seperated user ids"
      requires :message, :type => String, :desc => "Notification message"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post 'notify'  do

      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:read_any, User)

      status 200
      user_ids = params[:user_ids].split(',')

      user_ids.each do |id|

        user = User.select("id").where(id: id).first
        batch_notification(user,params[:message]) if user

      end

      "Notification send"
    end
    # Complete admin Query :- Send custom Notification to users

    # Query :- Register a user through facebook
    # Method :- POST
    # Parameters :-
    #         provider :- Specify provider name
    #         access_token :- Enter access token
    #         email  :- Enter Email addresss
    # Response :-
    #         Send user information
    desc "Register a user through Facebook"

    params do

      requires :provider, :validate_provider_type => true, :desc => "Provider name, currently supports facebook"
      requires :access_token, :type => String,  :desc => "Enter the access token."
      requires :email, :type => String, :desc => "Enter the email id."
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

    end

    post ":provider/login" do

      client = FBGraph::Client.new(:client_id => Settings.facebook_app_id,:secret_id => Settings.facebook_app_secret,:token => params[:access_token])

      begin

        info = client.selection.me.info!
      rescue RestClient::BadRequest
        bad_request!(INVALID_DEVICE_TOKEN, "Invalid parameter: Access token is invaild.")

      end
      # Get user information using provider & token
      user = oauthorize(params[:provider].downcase,info)
      status 200
      {
        :provider_uid => info.id.to_i,
        :user_id => user.id,
        :name => info.name,
        :email => user.email,
        :authentication_token => user.authentication_token
      }

    end
    # Complete Query :- Provider Login

    # Query :- Send custom notification to all the users
    # Method :- POST
    # Parameters :-
    #         url  :- Custom URL
    #         message :- Custom message
    # Response :-
    #         Send user information
    desc "send custom push notification to all the users. "

    params do

      optional :url,:desc => "Custom url"
      requires :message, :type => String, :desc => "Custom message"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post 'custom_notification'  do

      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:read_any, User)

      status 200
      User.all.each do |user|
        send_custom_notification(user)
      end
      "Notification send"

    end
    # Complete Query :- Send custom notification to all users

    # Query :- Verify that User authentication token & provide detail
    # Method :- POST
    # Parameters :-
    #         auth_token  :- User API Key
    #         registration_id :- Device Registration ID
    # Response :-
    #         Send status information
    desc "Verify that user authentication token"

    params do

      requires :upload_token,:desc => "User upload token"
      optional :registration_id, :type => String, :desc => "Device Registration ID "
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post 'authenticate_user'  do

      auth_user_status = device_status = false;
      status_reason = AuthStatus::UNKNOWN_STATUS;

      active_user = authenticated_user ;

      forbidden_request! unless active_user.has_authorization_to?(:read_any, User) ;

      # verify that User with access_token present or not.
      auth_user =  User.where("upload_token" => params[:upload_token]).first;

      # valid user with API server.
      if auth_user

        # check that User has valid token or not.
        if auth_user.has_valid_UploadToken()

          # User is present
          auth_user_status = true;
          status_reason = AuthStatus::USER_FOUND;

          if params[:registration_id]
            device = auth_user.devices.where(registration_id: params[:registration_id]).first ;
            device_status = true if device ;
          end

        else

          auth_user_status = false;
          status_reason = AuthStatus::INVALID_UPLOAD_TOKEN;

        end

      else
        status_reason = AuthStatus::INVALID_UPLOAD_TOKEN;

      end
      status 200
      {
        :auth_user_status => auth_user_status,
        :device_status => device_status,
        :status_reason => status_reason
      }
    end
    # Complete Query :- Verify that user authentication token


    # Query :- Get Upload Token from API Server to upload files into S3 Bucket
    # Method :- GET
    # Parameters :-
    #         None
    # Response :-
    #         Send Upload Token information
    desc "Get Upload token which is used in Upload server for uploading image file"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

    post 'upload_token' do

      expire_at = 0;
      active_user = authenticated_user;
      generate_new_token = false;

      if ( active_user.upload_token)

        expiry_time = Time.now.utc.to_i + HubbleConfiguration::USER_UPLOAD_TOKEN_MIN_EXPIRE_TIME_SECONDS;

        if (( expiry_time) > (active_user.upload_token_expires_at.to_i) )
          generate_new_token = true ;
        end

      else
        generate_new_token = true;

      end

      if generate_new_token
        # Generate token with new expire time.
        active_user.upload_token = active_user.generate_upload_token() ;
        active_user.upload_token_expires_at = active_user.get_upload_token_expire_time() ;
        active_user.save! ;
      end

      if active_user.upload_token_expires_at
        expire_at = Time.at(active_user.upload_token_expires_at.to_i).utc;
      end

      status 200
      {
        :upload_token => active_user.upload_token,
        :expire_at => expire_at
      }
    end
    # Complete Query :- "Get Upload token which is used in Upload server for uploading image file"

    # Query :- DELETE Upload Token from API Server
    # Method :- DELETE
    # Parameters :-
    #         None
    # Response :-
    #         Status message
    desc "Delete upload token which is used for uploading files in Upload Server"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

    put 'reset_upload_token'  do

      active_user = authenticated_user ;

      active_user.upload_token = nil ;
      active_user.upload_token_expires_at = nil ;
      active_user.save! ;

      status 200
      {
        :query_message => DeviceMessage::RESET_UPLOAD_TOKEN,
      }
    end
    # Complete Query :- "Get Upload token which is used in Upload server for uploading image file"

  end
end
