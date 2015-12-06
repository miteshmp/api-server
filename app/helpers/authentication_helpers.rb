require 'ipaddress'
require 'ruby_regex'

module AuthenticationHelpers

  # Class :- "AlphaNumeric"
  # Description :- Validate attribute parameter
  class AlphaNumeric < Grape::Validations::Validator

    def validate_param!(attr_name, params)
      unless params[attr_name] =~ /^[[:alnum:]]+$/
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => "#{attr_name}: must consist of alpha-numeric characters only."
      end
    end

  end
  # Complete :- "AlphaNumeric" definition
  
  # Class :- "ValidateDeviceType"
  # Description :- Validate Device type parameter
  class ValidateDeviceType < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name].downcase

        when "camera" # upnp
          # valid parameter
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
          :message => 
          {
            :status => 400,
            :code => INVALID_DEVICE_TYPE,
            :message => "#{attr_name}: does not have valid value.",
            :more_info => Settings.error_docs_url %  INVALID_DEVICE_TYPE
          }
        end

    end
  end
  # Complete :- "ValidateDeviceType" definition
  
  # Class :- "ValidateNotificationType"
  # Description :- Validate notification type parameter
  class ValidateNotificationType < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name].downcase
        when "gcm"
        when "apns"
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
            :message =>
            {
              :status => 400,
              :code => INVALID_APP_TYPE,
              :message => "#{attr_name}: does not have valid value.",
              :more_info => Settings.error_docs_url %  INVALID_APP_TYPE
            }
      end
    end

  end
  # Complete :- "ValidateCertificateType"

  # Class :- "ValidateCertificateType"
  # Description :- Validate cert_type parameter
  class ValidateCertificateType < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name]
        when 0
        when 1
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
            :message =>
            {
              :status => 400,
              :code => INVALID_CERT_TYPE,
              :message => "#{attr_name}: does not have valid value.",
              :more_info => Settings.error_docs_url %  INVALID_CERT_TYPE
            }
      end
    end

  end
  # Complete :- "ValidateCertificateType"

  # Class :- "ValidateAlertFormat"
  # Description :- Validate alert type parameter
  class ValidateAlertFormat < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name]
        when 1
        when 2
        when 3
        when 4
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
            :message =>
            {
              :status => 400,
              :code => INVALID_ALERT_FORMAT,
              :message => "#{attr_name}: does not have valid value.",
              :more_info => Settings.error_docs_url %  INVALID_ALERT_FORMAT
            }
      end
    end

  end
  # Complete :- "ValidateAlertFormat"

  # Class name :- ValidateIpAddressFormat
  # Description :- Validate IP address given as "attr_name" parameter

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
  # End of class definition :- ValidateIpAddressFormat

  # Class name :- ValidateCapabilityFormat
  # Description :- Validate Capability given as "attr_name" parameter
  class ValidateCapabilityFormat < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      if params[attr_name].length < 10

        throw :error, :status => params[:suppress_response_codes] ? 200 : 400, 
          :message => {
            :status => 400,
            :code => INVALID_CAPABILITY_FORMAT,
            :message => "#{attr_name} does not seem to be a proper format.",
            :more_info => Settings.error_docs_url %  INVALID_CAPABILITY_FORMAT
          }

      end
    end

  end
  # Complete :- "ValidateCapabilityFormat" definition

  # Class name :- ValidateEmailFormat
  # Description :- Validate Email format
  class ValidateEmailFormat < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      unless params[attr_name].match(RubyRegex::Email)

        throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
          :message =>
          {
            :status => 400,
            :code => INVALID_EMAIL_FORMAT,
            :message => "#{attr_name} does not seem to be a proper email address.",
            :more_info => Settings.error_docs_url %  INVALID_EMAIL_FORMAT
          }
      end
    end

  end
  # Complete :- "ValidateEmailFormat"

  # Class name :- ValidatePortFormat
  # Description :- Validate port format
  class ValidatePortFormat < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      if (params[attr_name] <0) || (params[attr_name] >65535)

        throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
          :message =>
          {
            :status => 400,
            :code => INVALID_PORT,
            :message => "#{attr_name} does not seem to be a proper.",
            :more_info => Settings.error_docs_url %  INVALID_PORT
          } 
      end
    end

  end
  # Complete :- "ValidatePortFormat"

  # Class name :- ValidateEmailType
  # Description :- Validate Email type
  class ValidateEmailType < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name].downcase
        when "welcome"
        when "reset_password"
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
          :message =>
          {
            :status => 400,
            :code => INVALID_EMAIL_TYPE ,
            :message => "#{attr_name} does not have valid value." ,
            :more_info => Settings.error_docs_url % INVALID_EMAIL_TYPE
          }
      end
    end

  end
  # Complete :- "ValidateEmailType"

  # Class name :- ValidateProviderType
  # Description :- Validate provider type
  class ValidateProviderType < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name].downcase
        when "facebook"
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
            :message =>
            {
              :status => 400,
              :code => INVALID_EMAIL_TYPE ,
              :message => "#{attr_name} does not have valid value." ,
              :more_info => Settings.error_docs_url % INVALID_EMAIL_TYPE
            }
      end
    end

  end
  # Complete :- "ValidateProviderType"

  # Class name :- ValidateDeviceAccessibilityMode
  # Description :- Validate device accessibity
  class ValidateDeviceAccessibilityMode < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      case params[attr_name].downcase
        when "p2p" # p2p
        when "relay" # stun but relay due to symmetric nat
        else
          throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
            :message =>
            {
              :status => 400,
              :code => INVALID_DEVICE_ACCESSIBILITY_MODE,
              :message => "#{attr_name}: does not have valid value.",
              :more_info => Settings.error_docs_url %  INVALID_DEVICE_ACCESSIBILITY_MODE
            }
      end
    end

  end
  
  
  
  class ValidateDateTimeFormat < Grape::Validations::Validator

    def validate_param!(attr_name, params)

      begin
        DateTime.strptime(params[attr_name],'%Y-%m-%dT%H:%M:%S%z')
      rescue ArgumentError
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
            :message =>
            {
              :status => 400,
              :code => INVALID_DATETIME_FORMAT,
              :message => "#{attr_name}: does not have valid datetime format expected in '%Y-%m-%dT%H:%M:%S%z' format .",
              :more_info => Settings.error_docs_url %  INVALID_DATETIME_FORMAT
            }
      end  
          
    end
  end
  # Complete :- "ValidateDeviceAccessibilityMode"


  # Class name :- "Length"
  # Description :- validate length parameter
  class Length < Grape::Validations::SingleOptionValidator

    def validate_param!(attr_name, params)

      unless params[attr_name].length == @option
        throw :error, :status => params[:suppress_response_codes] ? 200 : 400,
          :message => 
          {
            :status => 400,
            :code => INVALID_PARAMETER_LENGTH ,
            :message => "#{attr_name}: has wrong length." ,
            :more_info => Settings.error_docs_url % INVALID_PARAMETER_LENGTH
          }
      end
    end

  end
  # Complete :- "length" definition

  class Validvalue < Grape::Validations::SingleOptionValidator
    def validate_param!(attr_name, params)
      unless @option.include?(params[attr_name])
       throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => 400,
          :message => "#{attr_name} value must lie within #{@option}",
          :more_info => Settings.error_docs_url %  400
        }
      end
    end
  end
  
  
  class ValidModelNo < Grape::Validations::SingleOptionValidator
    def validate_param!(attr_name, params)
      if DeviceModel.find_all_by_model_no(params[attr_name]).empty?
       throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
          :status => 400,
          :code => 400,
          :message => "#{attr_name} must be an registered model in server",
          :more_info => Settings.error_docs_url %  400
        }
      end
    end
  end

  # Module name :- warden
  def warden

    env['warden']

  end

  # Module name :- authenticated
  # Description :- Return array with status, user object if User access token is valid
  #                status :- Status that access token is valid or not
  #                user :-  if status is true, then there is below two possiblity for user
  #                                           1. current user object if access token or api key is valid.
  #                                           2. null value if xapp_token or warden authentication token is valid.
  #                         if status is false, then user object MUST be NULL.
  def authenticated

    # Require for devise gem
    if warden.authenticated?

      return { :status => true, :user => nil }

    elsif params[:access_token] or params[:api_key]

      # Get acess token or api key from HTTP parameter
      token = params[:access_token]
      token = params[:api_key] unless token

      user = User.find_for_token_authentication("access_token" => token)

      # Return true if user is present with access token
      if user

        return { :status => true, :user => user }

      else

        return { :status => false, :user => nil }

      end

    elsif params[:xapp_token]

      # authentication model is used to third party provider loging
      acesss = Authentication.find_access(params[:xapp_token])

      # get correct user information from user object based on access token
      user = User.find(access.user_id) if access

      return { :status => true, :user => user }

    else
      # access denie if access token is not valid & abort execution by access_denied.
      access_denied!
    end

  end

  # Module name :- current_user
  # Description :- Return user object if access token is valid.
  def current_user

    warden.user ||
    User.find_for_token_authentication("access_token" => params[:api_key]) ||
    User.find_for_token_authentication("access_token" => params[:access_token]) 

  end

  # Module name :- is_admin
  # Description : Module should check that current user is admin or not.

  def is_admin?

    current_user && current_user.is_admin?

  end


  # Module name :- authenticated_user
  # Description :- Check that current user is authorized or not.
  def authenticated_user

    # check that access token is valid or not in this module.
    # it should return user object & status
    # ToDo :- Check that "status" field of results because it is possible that "user" field of results may NULL.
    results = authenticated

    if results[:status]

      # Return user object
      return results[:user]

    else

      # invalid access token or api key
      access_denied!

    end
  end
  # complete module :- authenticated_user

  # Module name :- authenticated_admin
  # Description :- check that current user is admin or not
  def authenticated_admin

    # check that access token is valid or not & return status with user object.
    results = authenticated

    if results[:status]

        # check that return user object has admin privilege
        return results[:user].is_admin? if results[:user]
    else
      # invalid access token or api key
      access_denied!
    end

  end

  # Module name :- authenticated_device
  # Description :-  Get authentication device otherwise access denied.
  def authenticated_device(sentDeviceDeRegistrationMessage=false)

    # get device based on authenticatio token
    device = current_device;

    # it is possible that device is deleted from account OR
    # device has sent wrong authentication code. it is required that
    # server should sent "deregistration" message only when device is deleted
    # from account.
    unless device

      device = current_device_only_deleted ;

      if device
        access_denied!(sentDeviceDeRegistrationMessage);
      else
        access_denied!(false);
      end

    end
    # return device object
    device 

  end

  # Module name :- current_device
  # Description :- Return device based on authentication token.
  def current_device

    begin

      device = Device.where(auth_token: params[:auth_token]).first

    rescue ActiveRecord::RecordInvalid => recordInValid
      internal_error!(DATABASE_VALIDATION_ERROR,"Database error");

    end
  end

  # Module name :- current_device_with_deleted
  # Description :- Return device based on authentication token.
  def current_device_with_deleted
    device = Device.with_deleted.where(auth_token: params[:auth_token]).first
  end

  # Module name :- current_device_only_deleted
  # Description :- Return device based on authentication token.
  def current_device_only_deleted
    device = Device.only_deleted.where(auth_token: params[:auth_token]).first
  end

end