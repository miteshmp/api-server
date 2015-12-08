require 'digest'
module APIHelpers
  def access_denied!
    e = { "status" => 401,
      "code" => 401,
      "message" => "Access Denied. The login-password combination OR the authentication token is invalid.",
      :more_info => Settings.error_docs_url %  401
    }

    error! e, params[:suppress_response_codes] ? 200 : 401
  end

  def bad_request!
    e = { "status" => 400,
      "code" => 400,
      "message" => "Bad Request",
      :more_info => Settings.error_docs_url %  400
    }

    error! e, params[:suppress_response_codes] ? 200 :400

  end

  def invalid_parameter!(parameter_name)
    e = { "status" => 400,
      "code" => 400,
      "message" => "Invalid parameter: " + parameter_name,
      :more_info => Settings.error_docs_url %  400
    }

    error! e, params[:suppress_response_codes] ? 200 : 400
  end

  def bad_request!(error_code, message)
    e = { "status" => 400,
      "code" => error_code,
      "message" => message,
      :more_info => Settings.error_docs_url %  error_code
    }

    error! e, params[:suppress_response_codes] ? 200 : 400
  end
  def forbidden_request!
    e = { "status" => 403,
      "code" => 403,
      "message" => "Unauthorized",
      :more_info => Settings.error_docs_url %  403
    }

    error! e, params[:suppress_response_codes] ? 200 : 403
  end

  def not_found!(error_code, element)
    e = { "status" => 404,
      "code" => error_code,
      "message" => "Not found! " + element.to_s,
      :more_info => Settings.error_docs_url %  error_code
    }

    error! e, params[:suppress_response_codes] ? 200 : 404
  end



  def invalid_request!(error_code, message)

    e = { "status" => 422,
      "code" => error_code,
      "message" => message,
      :more_info => Settings.error_docs_url %  error_code
    }

    error! e, params[:suppress_response_codes] ? 200 : 422
  end


  def internal_error!(error_code,  message)

    e = { "status" => 500,
      "code" => error_code,
      "message" => message,
      :more_info => Settings.error_docs_url %  error_code
    }

    error! e, params[:suppress_response_codes] ? 200 : 500
  end
 def internal_error_with_data!(error_code,  message, data)

    e = { "status" => 500,
      "code" => error_code,
      "message" => message,
      "data" => data,
      :more_info => Settings.error_docs_url %  error_code
    }

    error! e, params[:suppress_response_codes] ? 200 : 500
  end
  def encrypt(value)
    sha256 = Digest::SHA256.new    
    sha256.update (value)
    encrypted_value =  Base64.encode64(sha256.digest)
    encrypted_value
  end

end