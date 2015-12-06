# ArgumentError: invalid byte sequence in UTF-8
# It’s not a security issue as well. It’s just an invalid byte sequence in your request url. 
# Either way it would be good to fix it, even for a sole purpose of getting rid of this from our bug tracker.

module Hubble

  class Utf8Sanitizer
  
    SANITIZE_ENV_KEYS = %w(
      HTTP_REFERER
      PATH_INFO
      REQUEST_URI
      REQUEST_PATH
      QUERY_STRING
    )
 
    def initialize(app)
      @app = app
    end
 
  
    def call(env)
    
      SANITIZE_ENV_KEYS.each do |key|

        string = env[key].to_s
        valid = URI.decode(string).force_encoding('UTF-8').valid_encoding?
        # Don't accept requests with invalid byte sequence
        return [ 400, { }, [ 'Bad request' ] ] unless valid
    
      end
 
      @app.call(env)
    end

  end
end
