#     require 'rjb'
require 'grape'

class UtilsAPI_v1 < Grape::API

  include Audited::Adapters::ActiveRecord
  version 'v1', :using => :path,  :format => :json
  format :json
  formatter :json, SuccessFormatter

  # Helper method defined in below module
  helpers HubbleHelper ;
  helpers StunHelper ;


  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  # Resource name :- utils
  resource :utils do

    # Query :- Change role of a specific user"
    # Method :- PUT
    # Parameters :-
    #         roles  :- Comma separated list of roles
    # Response :-
    #         Response message
    desc "Change role of a specific user" 

      params do
        requires :roles, :type => String, :desc => "Comma separated list of roles ( roles include admin , user , factory_user , helpdesk_agent , tester ,bp_server, wowza_user, talk_back_user, marketing_admin)"
      end

      put ':id/change_role' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:change_role, User)


        user = User.select("id,roles_mask,name,email").where(id: params[:id]).first ;
        not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user

        roles = params[:roles].split(',')
        roles.each do |role|
          bad_request!(INVALID_REQUEST, "Role is not present") unless ROLES.include? role
        end

        admins = User.with_role :admin
        wowza_users = User.with_role :wowza_user
        bp_server = User.with_role :bp_server
        talk_back_users = User.with_role :talk_back_user

        if user.is? :admin  # Keep one admin
          bad_request!(INVALID_REQUEST, "One admin should be present") if admins.count == 1
        elsif user.is? :wowza_user
          bad_request!(INVALID_REQUEST, "One wowza user should be present") if wowza_users.count == 1
        elsif user.is? :talk_back_user
          bad_request!(INVALID_REQUEST, "One talk_back_user should be present") if talk_back_users.count == 1  
        end

        # Assign roles to User
        user.roles = roles

        bad_request!(INVALID_REQUEST, "Only one user with role bp_server is allowed") if roles.include?("bp_server") && bp_server.count >= 1
        bad_request!(INVALID_REQUEST, "Only one user with role talk_back_user is allowed") if roles.include?("talk_back_user") && talk_back_users.count >= 1

        user.save!

        status 200
        "Done"

      end
    # Complete Query :- "change_role"

    ###############################################################################################################################
    # Admin queries
    ###############################################################################################################################


    # Query :- Get settings.
    # Method :- GET
    # Parameters :-
    #       None
    # Response :-
    #         Return System setting information
    desc "Get settings. (Admin access needed)"

      get "system_settings" do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:manage, :all)
        status 200
        Settings.merge(GeneralSettings.all)
      end
    # Complete Query :- "system_settings"

    # Query :- Create or update settings.
    desc "Update or create settings. (Admin access needed)"
    params do
      requires :key, :type => String, :desc => "Key"
      requires :value, :desc => "Value"
    end  

      post "system_settings" do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:manage, :all)
        status 200
        GeneralSettings[params[:key]] = params[:value]
        "done"
      end
    # Complete Query :- "system_settings"

    # Query :- Get Server status
    # Method :- GET
    # Parameters :-
    #         None
    # Response :-
    #         Return Server staus information

    desc "Get Server status(Admin access needed)"

      get 'server_status' do

        active_user  = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:manage, :all)

        urls = [
          Settings.urls.portal_agent,
          Settings.urls.wowza_server,
          Settings.urls.upload_server
        ];

        server_status_hash = Hash.new ;
        status_threads = [] ;

        urls.each do |url|
          status_threads << Thread.new {

            begin
              response = HTTParty.get(url)

              if response.code == 200
                server_status_hash[url] = "on"
              else
                server_status_hash[url] = "off"
              end

              rescue Errno::ECONNREFUSED
                server_status_hash[url] = "off"

              rescue SocketError => exception
                server_status_hash[url] = "off"

              ensure
                  ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                  ActiveRecord::Base.clear_active_connections! ;
            end
          }
        end

        stun_urls = [Settings.urls.stun1_server,Settings.urls.stun2_server] ;
        semaphore = Mutex.new
        
        stun_urls.each do |stun_url|
          
          status_threads << Thread.new {
            
            socket = UDPSocket.new
            response = nil
            retries = 3

            begin

              Timeout::timeout(Settings.time_out.server_status_timeout) do
                semaphore.synchronize {
                  socket.send(Settings.stun.stun_1_2_byte_array.pack('C*'), 0, stun_url, 3478)
                  response = socket.recvfrom(Settings.stun.response_maxlen)
                }
              end
              server_status_hash[stun_url] = "on" if response
 
              rescue Timeout::Error
                retries -= 1
                if retries > 0
                  retry
                else
                  server_status_hash[stun_url] = "off"
                end

              rescue Errno::ECONNREFUSED
                server_status_hash[stun_url] = "off"

              rescue SocketError
                server_status_hash[stun_url] = "off"

              ensure
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;

            end
          } 
        end 

        stun_server_url = Settings.urls.stun_server

        status_threads << Thread.new {

          socket = UDPSocket.new
          stun_response = nil
          retries = 3

          begin

            Timeout::timeout(Settings.time_out.server_status_timeout) do
                 
                 socket.send(Settings.stun.byte_array.pack('C*'), 0,stun_server_url, 3478)    
                 stun_response  = socket.recvfrom(Settings.stun.response_maxlen)
            
            end
            server_status_hash[stun_server_url] = "on" if stun_response 

            rescue Timeout::Error
              retries -= 1
              if retries > 0
                retry
              else
                server_status_hash[stun_server_url] = "off"
              end

            rescue Errno::ECONNREFUSED
              server_status_hash[stun_server_url] = "off"

            rescue SocketError
              server_status_hash[stun_server_url] = "off"

            ensure
              ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
              ActiveRecord::Base.clear_active_connections! ;
          
          end
        }

        status_threads.each { |thr| thr.join }
        status 200
        server_status_hash 
      end  
    # Complete query :- "server_status"

    # Query :- Get my ip_address.
    # Method :- GET
    # Parameters :-
    #       None
    # Response :-
    #         Return IP address
    desc "Get My ip_address"

      get 'what_is_my_ip' do

        active_user  =   authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:manage, :all);

        {
          :real_ip => env['HTTP_X_REAL_IP'],
          :remote_addr => env['REMOTE_ADDR'],
          :real_ip_or_remote_addr => env['HTTP_X_REAL_IP'] ||= env['REMOTE_ADDR'],
          :x_forward_for =>  env["HTTP_X_FORWARDED_FOR"],
          :client_ip => env['HTTP_CLIENT_IP'],
          :x_forward_for_or_remote_addr => env["HTTP_X_FORWARDED_FOR"] ||= env['REMOTE_ADDR']
        }
      end
    # Complete Query :- Get my_ip_address

    # Query :- Get the current time
    # Parameter :- 
    #         None
    # Descritpion:- Application should get time from NTP time server. In worst case,if it is not able to
    #               get time from server, then it should get time from API server.
    desc "Get the current time. "

      get 'current_time' do
        status 200
        {
          "current_time" => Time.now.utc
        }
      end
    # Complete Query :- "current_time"


    # Query :- Get all API call issue
    # Method :- GET
    # Parameters :-
    #       None
    # Response :-
    #         Return all API call issue
    desc "Get all api call issues. "
      get 'api_call_issues' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, ApiCallIssues) ;
        status 200
        present ApiCallIssues.all, with: ApiCallIssues::Entity

      end
    # Complete Query :- "api_call_issues"

    # Query :- Get List of all pending critical commands
    # Method :- GET
    # Parameters :-
    #       page :- Page Number
    #       size :- Size per Page
    # Response :-
    #         Return critical commands
    desc "List all pending critical commands. "

      params do
        optional :page, :type => Integer, :desc => "Page number."
        optional :size, :type => Integer, :desc => "Number of records per page (defaut 10)."
      end

      get 'critical_commands' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, ApiCallIssues)   
        status 200
        present DeviceCriticalCommand.paginate(:page => params[:page], :per_page => params[:size]) , with: DeviceCriticalCommand::Entity
      end
    # Complete query :- "critical_commands"


    # Query :- Reactivate user account
    # Method :- POST
    # Parameters :-
    #       email :- Provide Email address
    # Response :-
    #         Return message that "user account reactivated"
    desc "Reactivate user account"

      params do
        requires :email, :type => String, :desc => "Email id."
      end

      post 'reactivate' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:update, User)

        status 200
        user = User.only_deleted.where(email: params[:email]).first
        not_found!(USER_NOT_FOUND, "User: " + params[:email].to_s) unless user
        user.recover
        "User account reactivated"
      end
    # Complete Query :- "reactivate" 

    # Query :- Get API Server Version
    # Method :- GET
    # Parameters :-
    #       None
    # Response :-
    #       Return server version informaton
    desc "API Server version"
      
      get 'version' do
          active_user = authenticated_user ;
          VERSION
      end
    # Complete Query :- "version"

    # Query :- Get list of all users. (Admin access needed)
    # Method :- GET
    # Parameters :-
    #       sSearch :- Search parameter
    #       page :- Page Number
    #       iDisplayStart :- Display start point
    #       iDisplayLength :- Number of records that table can display
    # Response :-
    #       Return List of Users
    desc "Get list of all users. (Admin access needed) "

      params do
        optional :sSearch, :type => String, :desc => "Global search parameter."
        optional :page, :type => Integer
        optional :iDisplayStart, :type => Integer , :desc => "Display start point in the current data set."
        optional :iDisplayLength, :type => Integer, :desc => "Number of records that the table can display in the current draw"
      end

      get do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, User)

        if params[:sSearch]
          users = User.paginate(:page => params[:page], :per_page => params[:iDisplayLength], :offset => params[:iDisplayStart]).find(:all, :conditions => ['email LIKE ?', "%#{params[:sSearch]}%"])
        else
          users = User.paginate(:page => params[:page], :per_page => params[:iDisplayLength], :offset => params[:iDisplayStart]).find(:all)
        end

        {
          :sEcho => 2,
          :iTotalRecords => User.count,
          :iTotalDisplayRecords => users.count,
          :aaData => users
        }
      end
    # Complete query :- "Get List of all Users"

    # Query :- Get Wowza Media Server URL and Server Region information
    # Method :- GET
    # Parameters :-
    #       client_ip :- Device Remote IP
    # Response :-
    #       Return List of Users
    desc "Get Wowza Media Server URL and Server Region information "

      params do
        optional :client_ip, :validate_ip_address_format => true, :desc => "Client IP Address"
      end

      get 'rtmp_ip' do

        active_user = authenticated_user ;

        # Get Remote IP address if client_ip is not defined
        remote_ip = ( params[:client_ip] != nil ) ? params[:client_ip] : get_ip_address ;
        country_iso_code = get_country_ISOCode(remote_ip);
        region_code = get_LoadBalancer_regionCode(country_iso_code);
        rtmp_ip = get_wowza_rtmp_address(region_code);

        status 200
        {
          :remote_ip => remote_ip,
          :iso_code => country_iso_code,
          :region_code => region_code,
          :rtmp_ip => rtmp_ip
        }
      end
    # Complete query :- "rtmp_ip"


    # Query :- Specify Action Configuration 
    # Method :- POST
    # Parameters :-
    #       action_name :- Action Name
    #       action_value :- Action value, it is based on action items.
    #       action_rule :- Action rules if any.
    # Response :-
    #       Return status message
    desc "Specify action configuration. (Admin Access Required)"

      params do
        requires :action_name,  :type => String, :desc => "Action name"
        requires :action_value, :type => String, :desc => "Action value. provide based on action items"
        requires :model_no,  :type => String, :desc => "Device Model Number"
        optional :action_rule,  :type => String, :desc => "Action rules if present"
      end

      post 'action_config' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:define_action, User)

        device_model = DeviceModel.where(model_no: params[:model_no]).first
        not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

        action_item = ActionConfig.new
        action_item.action_name  = params[:action_name];
        action_item.action_value = params[:action_value];
        action_item.device_model_id = device_model.id;
        action_item.action_rule  = params[:action_rule] if params[:action_rule] ;
        action_item.save! ;

        status 200
        action_item ;

      end
    # Complete query :- "post :- action_config"

    # Query :- Delete Specific Action
    # Method :- DELETE
    # Parameters :-
    #       action_name :- Action Name
    #       action_value :- Action value, it is based on action items.
    #       model_no :- Device Model No.
    # Response :-
    #       Return status message
    desc "Delete specify action configuration. (Admin Access Required)"

      params do

        requires :action_name,  :type => String, :desc => "Action name"
        requires :action_value, :type => String, :desc => "Action value. provide based on action items"
        requires :model_no,  :type => String, :desc => "Device Model Number"

      end

      delete 'action_config' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:define_action, User)

        device_model = DeviceModel.where(model_no: params[:model_no]).first
        not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

        action_items = ActionConfig.where(:action_name => params[:action_name],:action_value => params[:action_value],:device_model_id => device_model.id).destroy_all;


        status 200
        action_items ;

      end
    # Complete query :- "post :- action_config"

      desc "Get Marketing content"
      params do
        optional :page, :type => Integer, default: 1, :desc => "Page number."
        optional :size, :type => Integer, :desc => "Number of records per page (defaut 10)."
      end

      get 'marketing_content' do
        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, MarketingContent)

        params[:size] = Settings.default_page_size unless params[:size]  
        content = MarketingContent.paginate(:page => params[:page], :per_page => params[:size])
        present content, with: MarketingContent::Entity, type: :full
      end

      desc "Create Marketing content"
      params do
        requires :key, :type => String, :desc => "Unique key"
        requires :value, :type => String, :desc => "Value"
      end

      post 'marketing_content' do
        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, MarketingContent)

        marketing_content = MarketingContent.new
        marketing_content.key = params[:key]
        marketing_content.value = params[:value]
        Audit.as_user(active_user) do
          marketing_content.save!
        end
        status 200
        {
          :key => marketing_content.key,
          :value => marketing_content.value
        }
      end

      desc "Update Marketing content"
      params do
        requires :key, :type => String, :desc => "An existing key"
        requires :value, :type => String, :desc => "New value"
      end

      put 'marketing_content' do
        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, MarketingContent)

        marketing_content = MarketingContent.where(key: params[:key]).first()
        not_found!(INVALID_PARAMETER, "Key: " + params[:key].to_s) unless marketing_content
        marketing_content.value = params[:value]
        Audit.as_user(active_user) do
          marketing_content.save!
        end
        status 200
        {
          :key => marketing_content.key,
          :value => marketing_content.value
        }
      end

      desc "get urls"
      get 'urls' do
        active_user = authenticated_user

        status 200
        {
          :webapp_url => Settings.urls.webapp_url
        }
      end

  end
  # End of resource "utils"
end
# End of Class "utils"