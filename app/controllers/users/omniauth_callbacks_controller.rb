class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    oauthorize "Facebook"
  end

  def twitter
    oauthorize "Twitter"
  end

  def passthru
    render :file => "#{Rails.root}/public/404.html", 
    :status => 404, 
    :layout => false
  end

  
  def access_token
=begin
application = ClientApplication.authenticate(params[:client_id], params[:client_secret])
    if application.nil?
      render :json => {:error => "Could not find application"}
      return
    end
=end
    access_grant = Authentication.authenticate(params[:code], application.id)
    if access_grant.nil?
      render :json => {:error => "Could not authenticate access code"}
      return
    end
    access_grant.start_expiry_period!
    render :json => {
        :access_token => access_grant.access_token,
        :refresh_token => access_grant.refresh_token,
        :expires_in => access_grant.access_token_expires_at
    }
  end
  
  
  private

  def oauthorize(kind)

    omniauth = request.env['omniauth.auth']
    # TODO : Handle case when email id is null
    @user = User.includes(:authentications).merge(Authentication.where(:provider => omniauth['provider'], :uid => omniauth['uid'])).first
    if @user # if user exists and has used this authentication before, update details and sign in
      @user.set_token_from_hash(provider_auth_hash(kind, omniauth), provider_user_hash(kind, omniauth))
      sign_in_and_redirect @user, :event => :authentication
    elsif current_user # if user exists then new authentication is being added - so update details and redirect to
      user = User.where(email: omniauth['extra']['raw_info']['email']).first
      user.authentications.build(provider_auth_hash(kind, omniauth))
      if user
          if user.save :validate => false # validate false handles cases where email not provided - such as Twitter
          sign_in_and_redirect(:user, user)
        else # validate false above makes it almost impossible to get here
          session["devise.#{kind.downcase}_data"] = provider_auth_hash(kind,omniauth).merge(provider_user_hash(kind,omniauth))
          redirect_to new_user_registration_url
        end
      else  
        current_user.set_token_from_hash(provider_auth_hash(kind, omniauth), provider_user_hash(kind, omniauth))
        sign_in_and_redirect @user, :event => :authentication
      end  
    else # create new user and new authentication
      user = User.new
      user.password = Devise.friendly_token[0,20]
      user.authentications.build(provider_auth_hash(kind, omniauth))
      if user.save :validate => false # validate false handles cases where email not provided - such as Twitter
        sign_in_and_redirect(:user, user)
      else # validate false above makes it almost impossible to get here
        session["devise.#{kind.downcase}_data"] = provider_auth_hash(kind,omniauth).merge(provider_user_hash(kind,omniauth))
        redirect_to new_user_registration_url
      end
    end

  end

  def provider_auth_hash(provider, hash)
    # Create provider specific hash's to populate authentication record
    case provider
    when "Facebook"
      {
        :provider => hash['provider'],
        :uid => hash['uid'],
        :access_token => hash['credentials']['token'],
        :secret => nil,
        :name => hash['extra']['raw_info']['name'],
        :link => hash['extra']['raw_info']['link']
      }
    when "Twitter"
      {
        :provider => hash['provider'],
        :uid => hash['uid'],
        :access_token => hash['credentials']['token'],
        :secret => hash['credentials']['secret'],
        :link => hash['info']['urls']['Twitter'],
        :name => hash['info']['nickname']

      }
    end
  end

  def provider_user_hash(provider, hash)
    # Create provider specific hash's to populate user record if appropriate
    case provider
    when "Facebook"
      {
        :name => hash['extra']['raw_info']['name'],
        :email => hash['extra']['raw_info']['email']
      }
    when "Twitter"
      {
        :name => hash['info']['name'],
        :email => ""
      }
    end
  end

end