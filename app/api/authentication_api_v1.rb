class AuthenticationAPI_v1 < Grape::API

  formatter :json, SuccessFormatter
  format :json
  default_format :json

  version 'v1', :using => :path, :format => :json

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :authentications do

    # Query :- Get list of authentications of current user.
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return User information
    desc "Get list of authentications of current user. "

      get do

        # check user account information & return active user object.
        active_user = authenticated_user

        if active_user

          present active_user.authentications, with: Authentication::Entity

        else

          access_denied!

        end

    end
    # Complete Query :- Get List of authentications of Current User.

  end

end