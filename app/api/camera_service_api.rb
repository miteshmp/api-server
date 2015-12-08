require 'grape'
require 'string'


class CameraServiceAPI < Grape::API

  format :txt
  default_format :txt
  prefix 'BMS'

  params do
    optional :action, :type => String, :desc => ""
    optional :command, :type => String, :desc => ""
  end
  helpers APIHelpers
  helpers AwsHelper
  helpers StunHelper
  helpers AuthenticationHelpers
  resource :cameraservice do
    get  do
      if params[:action] != "command"
        status 601
        "Invalid action..."
      else
        case params[:command]
        when "update_port_info"

          # command=update_port_info&ip=192.168.1.13&port1=44444&port2=44445&UPNPStatus=3&port3=4446
          
          
          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          elsif params[:port1].nil?
            status PARAMETER_MISSING
            "Parameter missing: port1"
          elsif !(params[:port1].is_i?)
            status INVALID_PARAMETER_FORMAT
            "Invalid port1 format"
          elsif params[:port2].nil?
            status PARAMETER_MISSING
            "Parameter missing: port2"
          elsif !(params[:port2].is_i?)
            status INVALID_PARAMETER_FORMAT
            "Invalid port2 format"
          elsif(params[:port3] && !params[:port3].is_i?) 
            status INVALID_PARAMETER_FORMAT
            "Invalid port3 format" 
          elsif(params[:port4] && !params[:port4].is_i?) 
            status INVALID_PARAMETER_FORMAT
            "Invalid port4 format"       
          elsif params[:UPNPStatus].nil?
            status PARAMETER_MISSING
            "Parameter missing: UPNPStatus"
          elsif !(params[:UPNPStatus].is_i?)
            status INVALID_PARAMETER_FORMAT
            "Invalid UPNPStatus format"
          else
            authenticated_device
            ip = params[:ip]
            if ip
              if ip.length == 0
                ip = nil
              elsif  params[:ip].length < 7 || !(IPAddress.valid? params[:ip])
                status INVALID_PARAMETER_FORMAT
                return "Invalid IP Address format"
              end
            end
            
            location = current_device.device_location
            location.remote_ip = ip if ip
            location.remote_port_1 = params[:port1]
            location.remote_port_2 = params[:port2]  
            location.remote_port_3 = params[:port3] if params[:port3]           
            location.remote_port_4 = params[:port4] if params[:port4] 

            location.save!

            Settings.camera_service.update_port_info_response
          end

        when "set_stream_mode"
          # command=set_stream_mode&value=2&fwversion=8.310
          
          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          elsif params[:value].nil?
            status PARAMETER_MISSING
            "Parameter missing: value"
          elsif  !(params[:value].is_i?)
            status INVALID_PARAMETER_FORMAT
            "Invalid value format"
          else
            authenticated_device
            mode = 0
            
            case params[:value]
            when "upnp","2" # upnp
              mode = 1
            when "stun","3" # stun
              mode = 2
            when "relay","5" # stun but relay due to symmetric nat
              mode = 3
            else
              throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
                :status => 400,
                :code => INVALID_DEVICE_ACCESSIBILITY_MODE,
                :message => "'mode' does not have valid value.",
                :more_info => Settings.error_docs_url %  INVALID_DEVICE_ACCESSIBILITY_MODE
              }
            end
            device = current_device
            device.mode = mode

            device.firmware_version = params[:fwversion] if params[:fwversion]

            device.save!

            Thread.new{
              device.device_critical_commands.each do |critical_command|
                response = send_command_over_stun(device, critical_command.command)
                critical_command.destroy if response[:device_response][:device_response_code] == 200
              end  
            } 
            
            Settings.camera_service.set_stream_mode_response

          end


        when "is_port_open"
          # command=is_port_open&ipaddress=183.178.17.86&port=47899
          
          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          elsif params[:port].nil?
            status PARAMETER_MISSING
            "Parameter missing: port"
          elsif !(params[:port].is_i?)
            status INVALID_PARAMETER_FORMAT
            "Invalid port format"
          else
            authenticated_device
            ip_address = get_ip_address
            port = params[:port]
            port_status = true

            begin 
              Timeout::timeout(Settings.time_out.is_port_open_timeout) do        
                Socket.tcp(ip_address, port) {|sock|
                  sock.close
                }
              end

              status 200
              Settings.camera_service.port_open_response % [params[:port] , ip_address]

            rescue Timeout::Error
              port_status = false
              status STREAMING_PORT_CLOSED
              Settings.camera_service.port_closed_response % [params[:port] , ip_address]
              
            rescue
              port_status = false 
              status STREAMING_PORT_CLOSED
              Settings.camera_service.port_closed_response % [params[:port] , ip_address]
              
            end
          end


        when "notification"
          # command=notification&alert=3&val=low-temp&url=
          
          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          elsif params[:val].nil?
            status PARAMETER_MISSING
            "Parameter missing: value"
          elsif params[:alert].nil?
            status PARAMETER_MISSING
            "Parameter missing: alert"
          else
            authenticated_device
            device = current_device
            user = User.where(id: device.user_id).first
            not_found!(USER_NOT_FOUND, "User: " + device.user_id.to_s) unless user

            target_arn_gcm = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint)
            target_arn_apns = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint)
            
            notification_threads = []
            target_arn_gcm.each do |target_arn|
              notification_threads << Thread.new {
                send_push_notification(target_arn,device,"gcm")
              }
            end

            target_arn_apns.each do |target_arn|
              notification_threads << Thread.new {
                send_push_notification(target_arn,device,"apns")
              }
            end 
            Thread.new{
              event = device.device_events.new
              event.alert = params[:alert]
              event.time_stamp =Time.now
              event.value = params[:val]
              event.event_code = params[:ftpUrl] if params[:ftpUrl]
              event.save!
            }
            
            target_arn_list = target_arn_gcm + target_arn_apns
            all_target_arn_list = target_arn_list.join(",")
            status 200
            Settings.camera_service.notification_response % [all_target_arn_list , target_arn_gcm.count , target_arn_apns.count]
          end

        when "receive_reset_request"
          # command=receive_reset_request
          authenticated_device
          internal_error!(IMPLEMENTATION_PENDING,"Implementation pending.")
          
          


        when "success_update"
          # command=success_update&version=1.20.0
          

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          elsif params[:version].nil?
            status PARAMETER_MISSING
            "Parameter missing: version"
          else
            authenticated_device 
            device = current_device
            device.firmware_version = params[:version] if params[:version]
            device.save!
          end

        when "set_access_token"
          # command=set_access_token&value=xxxxxxxxxxxxxxx
          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          elsif params[:value].nil? || params[:value].is_empty?
            status PARAMETER_MISSING
            "Parameter missing: value "
          else
            authenticated_device
            device = current_device           
            device.access_token = params[:value]
            device.save!
            Settings.camera_service.set_access_token_response
          end

        when "get_current_time"
          # command=get_current_time
          Time.now.utc  
        
        when "get_rtmp_ip"
        # command=get_rtmp_ip

            if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"
            else
              authenticated_device
              if(Settings.urls.wowza_server[0..3].upcase == "HTTP")
                  uri = "%s:%s/loadbalancer" % [Settings.urls.wowza_server,Settings.urls.wowza_http_port] 
              else
                  httpUri = "http://" + Settings.urls.wowza_server
                  uri = "%s:%s/loadbalancer" % [httpUri,Settings.urls.wowza_http_port] 

              end
            begin
              Timeout::timeout(Settings.time_out.wowza_server_timeout) do 
                response =  HTTParty.get(uri)
                status 200
                rtmp_ip= "rtmp_ip="+response.split('=').last
              end  
            rescue Timeout::Error
               internal_error!(TIMEOUT_ERROR,"Timeout occured in connecting wowza load balancer server ")     #has to move all internal error messages to config file
            rescue Errno::ETIMEDOUT
               internal_error!(TIMEOUT_ERROR,"HTTP Timeout occured  in connecting wowza load balancer server  ")
            rescue Errno::ECONNREFUSED => e      
               internal_error!(TIMEOUT_ERROR,"Wowza load balancer server not responding")
            end
         end            
        else
          status 601
          "Invalid command passed."
        end
      end
    end
  end

  resource :cameraservice do
    post  do
      if params[:action] != "command"
        status 601
        "Invalid action..."
      else
        case params[:command]
        when "update_cam_ip1"
          # command=update_cam_ip&mac=987654321012
          status 200
          ip_address = get_ip_address
          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"
          else
            authenticated_device
            if params[:local_ip]
              if  params[:local_ip].length < 7 || !(IPAddress.valid? params[:local_ip])
                status INVALID_PARAMETER_FORMAT
                return "Invalid IP Address format"
              end
            end
            device = current_device
            #location = device.device_location
            #location.remote_ip = ip_address
            #location.local_ip = params[:local_ip] if params[:local_ip]
            #location.save!
            
            Settings.camera_service.upate_ip_response % [ip_address , device.registration_id , params[:local_ip]]
            # todo cameraservice line:1481
          end
        else
          status 601
          "Invalid command passed."
        end
      end
    end
  end  
end
