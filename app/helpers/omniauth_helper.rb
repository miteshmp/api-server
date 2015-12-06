# Module name :- "OmniauthHelper"
# Description :- This module helps for third party authorization process.
module OmniauthHelper

    # Method :- "oauthorize"
    # Description :- Return user informtation based on Client info.
    def oauthorize(kind,client_info)
        user = User.where(email: params[:email]).first
        unless  user
            user = User.new ;
            user.name = client_info.name ;
            user.email = params[:email] ;
            create_password = Devise.friendly_token[0,20] ;
            user.password = create_password ;
            user.password_confirmation = create_password ;
            user.save!
            user.reset_authentication_token!
        end
        set_token_from_hash(user,provider_auth_hash(kind, client_info)) ;
        user ;
    end
    # Complete :- "oauthorize"

    # Method :- "set_token_from_hash"
    # Description :- Return user informtation based on Client info.	
	def set_token_from_hash(user,auth_hash)
        token = user.authentications.where(provider: params[:provider],uid: auth_hash[:uid]).first
        token = user.authentications.new unless token
        token.name = auth_hash[:name] ;
        token.link = auth_hash[:link] ;
        token.access_token = auth_hash[:access_token] ;
        token.secret = auth_hash[:secret] ;
        token.uid = auth_hash[:uid] ;
        token.provider = params[:provider] ;
        token.save! ;
    end
    # Complete :- "set_token_from_hash"

    # Method :- "provider_auth_hash"
    def provider_auth_hash(provider, client_info)
        # Create provider specific hash's to populate authentication record
        case provider
            when "facebook"
            {
                :provider => provider,
                :uid => client_info.id,
                :access_token => params[:access_token],
                :secret => nil,
                :name => client_info.name,
                :link => client_info.data.link
            }
    
            when "twitter"
            {
                :provider => provider,
                :uid => client_info.uid,
                :access_token => params[:access_token],
                :secret => params[:secret],
                :link => client_info.data.link,
                :name => client_info.name

            }
        end
    end
    # Complete :- "provider_auth_hash"
end
# Complete :- "OmniauthHelper" module
