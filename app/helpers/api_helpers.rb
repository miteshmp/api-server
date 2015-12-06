# This file contains definition of API Server related modules.
require 'digest'

module APIHelpers

  # Module :- access_denied.
  # Detail :- When Authorization failed, then API Server should send
  #           below response message to remote party.

  def access_denied!(sentDeviceDeRegistrationMessage=false)

    exception =
      {
        "status" => 401,
        "code"   => 401,
        "message" => "Access Denied. The login-password combination OR the authentication token is invalid.",
        :more_info => Settings.error_docs_url %  401
      }

      if sentDeviceDeRegistrationMessage

        logSentDeviceDeRegistrationMessage();
        error! exception, HubbleHttpStatusCode::DEVICE_UN_REGISTER_CODE

      else
        # "error" is part of "grape" gem, it will abort execution of API method.
        error! exception, params[:suppress_response_codes] ? 200 : 401
      end

  end

  # Module :- "logSentDeviceDeRegistrationMessage"
  def logSentDeviceDeRegistrationMessage

    # Required to verifiy device based authentication token
    if params[:auth_token]

      Thread.new {

        begin
          
          active_device = current_device_with_deleted ;
  
          if active_device
            send_hubble_device_issue_mail(
                                            active_device,
                                            HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_ID,
                                            HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_TYPE,
                                            HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_REASON,
                                            "N/A",
                                            env["HTTP_HOST"]
                                            )

            api_call_issue = ApiCallIssues.where("api_type = ? AND error_reason = ? AND error_data = ?",
                                          HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_TYPE,
                                          HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_REASON,
                                          active_device.registration_id.to_s).first

            unless api_call_issue

              api_call_issue = ApiCallIssues.new
              api_call_issue.api_type = HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_TYPE ;
              api_call_issue.error_data = active_device.registration_id.to_s ;
              api_call_issue.error_reason = HubbleIssueNotification::DEVICE_DE_REGISTER_SENT_MESSAGE_REASON ;
              api_call_issue.save! ;

            end

          end

          rescue Exception => exception
          ensure
            ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
            ActiveRecord::Base.clear_active_connections! ;

        end
      }
    end
    # complete if condition
  end


  # Module :- Bad Request
  # When Request URL is not existed then API server should provide 
  # below response message to remote party.
  def bad_request!
    e =
    {
      "status" => 400,
      "code" => 400,
      "message" => "Bad Request",
      :more_info => Settings.error_docs_url %  400
    }
    error! e, params[:suppress_response_codes] ? 200 :400
  end

  # Module    :- Invalid Parameter
  # Parameter :- Invalid parameter is given by User.
  # When requested API contains invalid parameters, API server should provide
  # below response message to remote party.
  def invalid_parameter!(parameter_name)
    e =
    {
      "status" => 400,
      "code" => 400,
      "message" => "Invalid parameter: " + parameter_name,
      :more_info => Settings.error_docs_url %  400
    }
    error! e, params[:suppress_response_codes] ? 200 : 400
  end

  # Module :- Bad Request
  # Parameter :- Error code & Message
  # API Server should provide response with error code with message.
  def bad_request!(error_code, message)
    e =
    {
      "status" => 400,
      "code" => error_code,
      "message" => message,
      :more_info => Settings.error_docs_url %  error_code
    }
    error! e, params[:suppress_response_codes] ? 200 : 400
  end

  # Module :- Forbidden Request
  def forbidden_request!
    e =
    {
      "status" => 403,
      "code" => 403,
      "message" => "Unauthorized",
      :more_info => Settings.error_docs_url %  403
    }
    error! e, params[:suppress_response_codes] ? 200 : 403
  end

  # Module :- Not Found 
  # When Resource is not found, then API server should provide
  # below response message to remote party.
  def not_found!(error_code, element)
    e =
    {
      "status" => 404,
      "code" => error_code,
      "message" => "Not found! " + element.to_s,
      :more_info => Settings.error_docs_url %  error_code
    }
    error! e, params[:suppress_response_codes] ? 200 : 404
  end


  # Module :- Invalid Request
  # When invalid request is given by User, API server should provide
  # below response message to remote party.
  def invalid_request!(error_code, message)
    e =
    {
      "status" => 422,
      "code" => error_code,
      "message" => message,
      :more_info => Settings.error_docs_url %  error_code
    }
    error! e, params[:suppress_response_codes] ? 200 : 422
  end

  # Module :- Internal Error
  # When API server is failed to execute requested query, it should provide
  # below response to remote party.
  def internal_error!(error_code,  message)
    e =
    {
      "status" => 500,
      "code" => error_code,
      "message" => message,
      :more_info => Settings.error_docs_url %  error_code
    }
    error! e, params[:suppress_response_codes] ? 200 : 500
  end
  
  # Module :- Internal error with data
  # When API server is failed to execute requested query, it should provide
  # below response message with error code & message.
  def internal_error_with_data!(error_code,  message, data)
    e =
    {
      "status" => 500,
      "code" => error_code,
      "message" => message,
      "data" => data,
      :more_info => Settings.error_docs_url %  error_code
    }
    error! e, params[:suppress_response_codes] ? 200 : 500
  end

  # Module :- Encrypt 
  # Below module is used to encrypt "value" parameter using SHA256 Algorithm.
  def encrypt(value)
    sha256 = Digest::SHA256.new    
    sha256.update (value)
    encrypted_value =  Base64.encode64(sha256.digest)
    encrypted_value
  end

  # Module :- supportnewVersion
  # This module should verify that device is able to support new version of API server or not.
  def supportnewVersion!(device_model, firmware_version)

    if (Gem::Version.new(firmware_version) < Gem::Version.new(HubbleConfiguration::NEW_SERVER_VERSION))
      return false;
    end
    true;
  end

  # Module :- supportUploadTokenFeature
  # This module should verify that device is able to support new version of API server or not.
  def supportUploadTokenFeature!(firmware_version,device_model)

    if ( ( Gem::Version.new(firmware_version) < Gem::Version.new(HubbleConfiguration::UPLOAD_SERVER_VERSION)) ||
         ( (device_model.casecmp(HubbleDeviceModel::Focus73) == 0) && (Gem::Version.new(firmware_version) == Gem::Version.new(HubbleConfiguration::UPLOAD_SERVER_VERSION_0073)) )
       )
      return false;
    end
    true;
  end

  # Module :- supportEventTimeFeature
  # This module should verify that device is able to support new version of API server or not.
  def supportEventTimeFeature!(firmware_version)

    if (Gem::Version.new(firmware_version) < Gem::Version.new(HubbleConfiguration::EVENT_TIME_FEATURE_VERSION))
      return false;
    end
    true;
  end

  def failed_dependency!(message)
    e =
    {
      "status" => 424,
      "code" => 424,
      "message" => message,
      :more_info => Settings.error_docs_url %  424
    }
    error! e, params[:suppress_response_codes] ? 200 :424
  end



end
