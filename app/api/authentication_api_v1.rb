class AuthenticationAPI_v1 < Grape::API
  formatter :json, SuccessFormatter
  format :json
  default_format :json



  version 'v1', :using => :path, :format => :json

   params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end
  
  resource :authentications do
    desc "Get list of authentications of current user. "
    get do
      authenticated_user
      present current_user.authentications, with: Authentication::Entity
    end
  end
end