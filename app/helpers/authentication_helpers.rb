require 'ipaddress'
require 'ruby_regex'

module AuthenticationHelpers

  
  

  class AlphaNumeric < Grape::Validations::Validator
    def validate_param!(attr_name, params)
      unless params[attr_name] =~ /^[[:alnum:]]+$/
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => "#{attr_name}: must consist of alpha-numeric characters only."
      end
    end
  end

  
  
  class ValidateDeviceType < Grape::Validations::Validator
    def validate_param!(attr_name, params)

      case params[attr_name].downcase
      when "camera" # upnp
      else
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_DEVICE_TYPE,
          :message => "#{attr_name}: does not have valid value.",
          :more_info => Settings.error_docs_url %  INVALID_DEVICE_TYPE
        }
      end
    end
  end


  
  class ValidateFormat < Grape::Validations::Validator
    def validate_param!(attr_name, params)
      is_valid =  /\A[a-zA-Z0-9_=&.]*\z/.match(params[attr_name])
      unless is_valid
       throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => 400,
          :message => "#{attr_name}: has invalid format.",
          :more_info => Settings.error_docs_url %  400
        }
      end
    end
  end
  

  class ValidateNotificationType < Grape::Validations::Validator
    def validate_param!(attr_name, params)

      case params[attr_name].downcase
      when "gcm" 
      when "apns"
      else
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_APP_TYPE,
          :message => "#{attr_name}: does not have valid value.",
          :more_info => Settings.error_docs_url %  INVALID_APP_TYPE
        }
      end
    end
  end

  class ValidateAlertFormat < Grape::Validations::Validator
    def validate_param!(attr_name, params)

      case params[attr_name]
      when 1 
      when 2
      when 3
      when 4
      else
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_ALERT_FORMAT,
          :message => "#{attr_name}: does not have valid value.",
          :more_info => Settings.error_docs_url %  INVALID_ALERT_FORMAT
        }
      end
    end
  end

  class ValidateIpAddressFormat < Grape::Validations::Validator
    def validate_param!(attr_name, params)

      # there is some problem with IPAddress.valid?
      # if we pass a single digit, say "1", then it returns "true" which is incorrect
      # so let's have our own check that IP Address should be at least 7 characters long

      if params[attr_name].length < 7 || !(IPAddress.valid? params[attr_name])
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_IP_ADDRESS_FORMAT,
          :message => "#{attr_name} does not seem to be a proper IP Address.",
          :more_info => Settings.error_docs_url %  INVALID_IP_ADDRESS_FORMAT
        }
      end
    end
  end
  class ValidateCapabilityFormat < Grape::Validations::Validator
    def validate_param!(attr_name, params)
      if params[attr_name].length < 10
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_CAPABILITY_FORMAT,
          :message => "#{attr_name} does not seem to be a proper format.",
          :more_info => Settings.error_docs_url %  INVALID_CAPABILITY_FORMAT
        }
      end
    end
  end


  class ValidateEmailFormat < Grape::Validations::Validator
    def validate_param!(attr_name, params)

      unless params[attr_name].match(RubyRegex::Email)

        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_EMAIL_FORMAT,
          :message => "#{attr_name} does not seem to be a proper email address.",
          :more_info => Settings.error_docs_url %  INVALID_EMAIL_FORMAT
        }
        
      end

    end
  end


  class ValidateEmailType < Grape::Validations::Validator
    def validate_param!(attr_name, params)
      case params[attr_name].downcase
      when "welcome"
      when "reset_password"
      else
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => INVALID_EMAIL_TYPE ,
          :message => "#{attr_name} does not have valid value." ,
          :more_info => Settings.error_docs_url % INVALID_EMAIL_TYPE
        }
        

      end
    end
  end


  class Length < Grape::Validations::SingleOptionValidator
    def validate_param!(attr_name, params)
      unless params[attr_name].length <= @option
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
        :message => "#{attr_name}: must be at the most #{@option} characters long."
      end
    end
  end


  def warden
    env['warden']
  end
  def authenticated
    if warden.authenticated?
      return true
    elsif params[:access_token] or params[:api_key]
      token = params[:access_token]
      token = params[:api_key] unless token



      user = User.find_for_token_authentication("access_token" => token)


      return user ? true : false



    elsif params[:xapp_token] and
      Authentication.find_access(params[:xapp_token])
      return true
    else
      access_denied!
    end
  end
  def current_user
    warden.user ||
    User.find_for_token_authentication("access_token" => params[:api_key]) ||
    User.find_for_token_authentication("access_token" => params[:access_token]) 
  end
  def is_admin?
    current_user && current_user.is_admin?
  end
  # returns 401 if there's no current user
  def authenticated_user
    authenticated
    access_denied! unless current_user
  end
  # returns 401 if not authenticated as admin
  def authenticated_admin
    authenticated
    access_denied! unless is_admin?
  end

  def authenticated_device
    access_denied! unless current_device
  end

  def current_device
    device = Device.where(auth_token: params[:auth_token]).first
  end  
end
