#     require 'rjb'
require 'grape'

class UtilsAPI_v1 < Grape::API
  version 'v1', :using => :path,  :format => :json
  format :json
  formatter :json, SuccessFormatter

  
    params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :utils do

    desc "Change role of a specific user" 
    params do
        requires :roles, :type => String, :desc => "Comma separated list of roles ( roles include admin , user , factory_user , helpdesk_agent , tester ,bp_server, wowza_user)"
    end
    put ':id/change_role' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:change_role, User)
      
     
      user = User.where(id: params[:id]).first
       not_found!(USER_NOT_FOUND, "User: " + params[:id].to_s) unless user
       roles = params[:roles].split(',')
       roles.each do |role|
        bad_request!(INVALID_REQUEST, "Role is not present") unless ROLES.include? role
       end
      admins = User.with_role :admin
      wowza_users = User.with_role :wowza_user
      bp_server = User.with_role :bp_server


      if user.is? params[:roles]
        bad_request!(INVALID_REQUEST, "Role is already "+params[:roles])
      elsif user.is? :admin  # Keep one admin
        bad_request!(INVALID_REQUEST, "One admin should be present") if admins.count == 1
      elsif user.is? :wowza_user
        bad_request!(INVALID_REQUEST, "One wowza user should be present") if wowza_users.count == 1
      end 
       user.roles = roles

      bad_request!(INVALID_REQUEST, "Only one user with role bp_server is allowed") if roles.include?("bp_server") && bp_server.count >= 1

       user.save!

       status 200
       "Done"
      end
    ###############################################################################################################################
    # Admin queries
    ###############################################################################################################################


  desc "Get settings. (Admin access needed)"
  get "system_settings" do
    authenticated_user
    forbidden_request! unless current_user.has_authorization_to?(:manage, :all)
  	status 200
  	{
  		:value => Settings
  	}
  end

  desc "Get Server status(Admin access needed)"     
    get 'server_status' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:manage, :all)


      urls = [ 
        Settings.urls.portal_agent,
        Settings.urls.wowza_server,
        Settings.urls.upload_server]

      server_status_hash = Hash.new      
      status_threads = []
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
          end 
           
        }

        end 
        stun_urls=[Settings.urls.stun1_server,Settings.urls.stun2_server]
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
            end 
          }    
        

        status_threads.each { |thr| thr.join }    

      status 200
      server_status_hash 
    end  

    desc "Get My ip_address"     
    get 'what_is_my_ip' do
    authenticated_user
    forbidden_request! unless current_user.has_authorization_to?(:manage, :all)   

      {
        :real_ip => env['HTTP_X_REAL_IP'],
        :remote_addr => env['REMOTE_ADDR'],
        :real_ip_or_remote_addr => env['HTTP_X_REAL_IP'] ||= env['REMOTE_ADDR'],
        :x_forward_for =>  env["HTTP_X_FORWARDED_FOR"],
        :client_ip => env['HTTP_CLIENT_IP'],
        :x_forward_for_or_remote_addr => env["HTTP_X_FORWARDED_FOR"] ||= env['REMOTE_ADDR']
       } 
    end


    desc "Get the current time. "    
    get 'current_time' do
      status 200
      {
        "current_time" => Time.now.utc
       } 
    end

    desc "Get all api call issues. "    
    get 'api_call_issues' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, ApiCallIssues)   
      status 200
      present ApiCallIssues.all, with: ApiCallIssues::Entity
    end

    desc "List all pending critical commands. "   
    params do
      optional :page, :type => Integer, :desc => "Page number."
      optional :size, :type => Integer, :desc => "Number of records per page (defaut 10)."
    end   
    get 'critical_commands' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, ApiCallIssues)   
      status 200
      present DeviceCriticalCommand.paginate(:page => params[:page], :per_page => params[:size]) , with: DeviceCriticalCommand::Entity
    end


       desc "Reactivate user account"
       params do
        requires :email, :type => String, :desc => "Email id."
       end 
       post 'reactivate' do
          authenticated_user
          forbidden_request! unless current_user.has_authorization_to?(:update, User)
          status 200
          user = User.only_deleted.where(email: params[:email]).first
          not_found!(USER_NOT_FOUND, "User: " + params[:email].to_s) unless user
          user.recover
          "User account reactivated"
       end 


  end
end
