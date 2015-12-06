# This files provides CameraService API for Monitor Device.
# Due to performance issue, Devie is not able support RESTFUL API,
# so it is required that device should use normal API to update status in API Server.

# Grape is a REST-like API micro-framework for Ruby
require 'grape'
require 'string'

# Extending GRAPE framework which provides RESTFUL API.
class CameraServiceAPI < Grape::API

  # Format specification
  format :txt
  default_format :txt

  # Apply below prefix name for every CameraService API
  prefix 'BMS'

  # Below parameters are required for every Camera Service API
  params do
    optional :action, :type => String, :desc => ""
    optional :command, :type => String, :desc => ""
  end

  # Helpers are required which contains module definition.
  helpers APIHelpers  # contains API related module, 
  helpers AwsHelper
  helpers StunHelper
  helpers AuthenticationHelpers
  helpers HubbleHelper
  helpers DeviceCommandHelper

  # Query :- BMS/cameraservice?
  # Method :- GET
  # Description :- All API are belongs to device.

  resource :cameraservice do

    get  do

      # check that action is given us "command"
      if params[:action] != "command"

        status 601
        "Invalid action..."

      else
        #  check that which command is given in query
        case params[:command]

          # Query :- action=command&command=update_port_info
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
              # get device based on authentication token
              active_device = authenticated_device

              if !(supportnewVersion!(active_device.registration_id[2..5],active_device.firmware_version))

                # device does not support new API server
                ip = params[:ip]
                if ip

                  if ip.length == 0
                    ip = nil ;

                  elsif  params[:ip].length < 7 || !(IPAddress.valid? params[:ip])
                    status INVALID_PARAMETER_FORMAT
                    return "Invalid IP Address format"

                  end
                end

                location = active_device.device_location
                unless location
                  active_device.device_location = DeviceLocation.new;
                  active_device.save! ;
                  location = active_device.device_location;
                end
                location.remote_ip = ip if ip
                location.remote_port_1 = params[:port1]
                location.remote_port_2 = params[:port2]
                location.remote_port_3 = params[:port3] if params[:port3]
                location.remote_port_4 = params[:port4] if params[:port4]

                location.save!

                Settings.camera_service.update_port_info_response

              else
                "Invalid query :- Server does not support query with this device mode & firmware version"
              end # End of "supportNewversion"

            end
          # End of when condition
          # Complete command action :- "update_port_info"

          # Query :- action=command&command=set_stream_mode
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

              active_device = authenticated_device ;


              mode = 0 ;

              case params[:value]

                when "upnp","2" # upnp
                  mode = 1 ;

                when "stun","3" # stun
                  mode = 2 ;

                when "relay","5" # stun but relay due to symmetric nat
                  mode = 3 ;

                when "p2p","6" # p2p
                  mode = 6 ;  

              else

                throw :error, :status => params[:suppress_response_codes] ? 200 : 400, :message => {
                  :status => 400,
                  :code => INVALID_DEVICE_ACCESSIBILITY_MODE,
                  :message => "'mode' does not have valid value.",
                  :more_info => Settings.error_docs_url %  INVALID_DEVICE_ACCESSIBILITY_MODE
                }

              end # end of case

              active_device.mode = mode
              active_device.firmware_version = params[:fwversion] if params[:fwversion]

              active_device.save!

              Thread.new {

                begin

                  active_device.device_critical_commands.each do |critical_command|
                    response = send_command_over_stun(active_device, critical_command.command)
                    critical_command.destroy if response[:device_response][:device_response_code] == 200
                  end

                  rescue Exception => exception
                  ensure
                    ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                    ActiveRecord::Base.clear_active_connections! ;
                end

              }

              Settings.camera_service.set_stream_mode_response

            end
          # Complete Query action :- "set_stream_mode"

          # Query :- action=command&command=is_port_open
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

              active_device = authenticated_device ;
              ip_address = get_ip_address ; # Define in Stun helper

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

            end # if..else condition.
          # End of "is_port_info" query

=begin
          # action=command&command=set_firmware_version
          when "set_firmware_version"
          #command=set_firmware_version&set_firmware_version&fwversion=<XX.YY.ZZ>

            if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"

            elsif params[:version].nil?
              status PARAMETER_MISSING
              "Parameter missing: version"

            elsif !(params[:version].match(/^\d+.\d+(.\d+)?$/))
              status INVALID_PARAMETER_FORMAT
              "Invalid version format"

            else
              active_device = authenticated_device;

              active_device.firmware_version = params[:version] if params[:version]

              active_device.save!

              Settings.camera_service.set_firmware_version_response

            end
        # End of "set_firmware_version" Query
=end

        # Query :- action=command&command=notification
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

            # Sent De-registration Message if device failed to authenticate
            active_device  = authenticated_device(true) ;
            active_user = nil ;

            if active_device.has_attribute?("user_id")

              active_user = User.where(id: active_device.user_id).first ;
              not_found!(USER_NOT_FOUND, "User: " + active_device.user_id.to_s) unless active_user

            else

              begin

                Device.connection.clear_query_cache ;
                active_device = current_device ;

                active_user = User.where(id: active_device.user_id).first ;
                not_found!(USER_NOT_FOUND, "User: " + active_device.user_id.to_s) unless active_user 

                rescue Exception => exception

                  Rails.logger.error("notification service :-  #{exception.message}");
                  internal_error!( ERROR_ACTIVE_RECORD, HubbleErrorMessage::ACTIVE_RECORD_ERROR_MESSAGE );
              end
            end

            child_id = nil
            parent_id = nil
            parent_device_name = nil
            if (params[:alert].to_i == EventType::DOOR_MOTION_DETECT_EVENT or params[:alert].to_i == EventType::PRESENCE_DETECT_EVENT)
              child_device = Device.where(registration_id: params[:trigger_by]).first
              not_found!(DEVICE_NOT_FOUND, "Device: " + params[:trigger_by]) unless child_device
              child_id = child_device.id
              parent_id = active_device.id
              parent_device_name = active_device.name
            end

            # Sends notification (message : success firware update
            # Convert alert type from int to string
            notification_status,response_code,response_message = send_notification( active_user, active_device, params[:alert], parent_device_name);

            external_notifier = ExternalNotifier.new({:device => active_device})
            external_notifier.send_push_notification({:device => active_device, :parameters => params})


            # Create a thread to store device event information.
            Thread.new {
              begin
                event = active_device.device_events.new
                event.alert = params[:alert]
                event.time_stamp =Time.now
                event.value = params[:val]
                event.event_code = params[:ftpUrl] if params[:ftpUrl]
                event.event_time = params[:time] if params[:time]
                event.storage_mode=  params[:storage_mode] == nil ? 0 : params[:storage_mode]
                if CameraServiceAPI.new.is_child_event?(params[:alert])
                  event.device_id = child_id
                  event.parent_id = parent_id
                end

                event.save!
                
                rescue Exception => exception
                            Rails.logger.error "caught exception #{exception}!" 
                ensure
                  ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                  ActiveRecord::Base.clear_active_connections! ;
              end
            }

            # store number of gcm & apns client
            arn_gcm_count  = 0;
            arn_apns_count = 0;


            begin
              # parse response message properly
              arn_gcm_count = response_message.split(":")[0];
              arn_apns_count = response_message.split(":")[1];
            rescue Exception => e
            end


            status 200
            Settings.camera_service.notification_response % [arn_gcm_count , arn_apns_count]

          end
        # End of Query :- "notification"

        # Query :- action=command&command=sdcard_clip_info
        when "sdcard_clip_info"
        # command=sdcard_clip_infoauth_token=[authen token]&clip_name=[flv clip name]&clip_sum=[md5 sum]&event_code=[event_code]
              if params[:auth_token].nil?
                status PARAMETER_MISSING
                "Parameter missing: auth_token"

              elsif params[:clip_name].nil?
                status PARAMETER_MISSING
                "Parameter missing: clip_name"

              elsif params[:clip_sum].nil?
                status PARAMETER_MISSING
                "Parameter missing: clip_sum"
             
              elsif params[:event_code].nil?
                status PARAMETER_MISSING
                "Parameter missing: event_code"   
             
              else
                active_device  = authenticated_device(true) ;
                device_event=DeviceEvent.where(device_id: active_device.id,event_code: params[:event_code]).first 
                  if !device_event.nil?
                    event_detail = DeviceEventDetail.new
                    event_detail.clip_name = params[:clip_name]
                    event_detail.device_event_id= device_event.id[0]
                    event_detail.md5_sum = params[:clip_sum]
                    event_detail.save!
                  else
                      not_found!(DEVICE_EVENT_CODE_NOT_FOUND, "Device Event: " + params[:event_code]) unless device_event  
                  end
                  status 200
              end

        # End of Query :- "sdcard_clip_info"

        # Query :- action=command&command=receive_reset_request
        when "receive_reset_request"
        # command=receive_reset_request

          active_device = authenticated_device
          internal_error!(IMPLEMENTATION_PENDING,"Implementation pending.")

        # End of Query :- receive_reset_request

        # Query :- action=command&command=get_upload_token&auth_token=<device auth token>
        when "get_upload_token"
        # command=get_upload_token

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"

          else

            active_device = authenticated_device ;
            active_device.upload_token = active_device.generate_upload_token ;
            active_device.upload_token_expires_at = active_device.get_upload_token_expire_time ;
            active_device.save! ;

            if active_device.upload_token
              return DeviceMessage::UPLOAD_TOKEN + DeviceMessage::MESSAGE_SEPATRATOR  + active_device.upload_token ;
            else
              return DeviceMessage::FAILED + DeviceMessage::MESSAGE_SEPATRATOR + DeviceMessage::UNKNOWN ;
            end

          end
        # End of Query :- get_upload_token

        # Query :- action=command&command=clear_upload_token&auth_token=<device auth token>
        when "clear_upload_token"
        # command=clear_upload_token

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"

          else

            active_device = authenticated_device ;
            active_device.upload_token = nil ;
            active_device.upload_token_expires_at = nil ;
            active_device.save! ;

            return DeviceMessage::CLEAR_UPLOAD_TOKEN ;

          end

        # End of Query :- get_upload_token


        # Query :- action=command&command=success_update
        when "success_update"
        # command=success_update&version=1.20.0

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"

          elsif params[:version].nil?
            status PARAMETER_MISSING
            "Parameter missing: version"

          elsif !(params[:version].match(/^\d+.\d+(.\d+)?$/))
            status INVALID_PARAMETER_FORMAT
            "Invalid version format"

          else
  
            sendNotification = false;
            # Sent De-registration Message if device failed to authenticate
            active_device  = authenticated_device(true) ;

            user = User.where(id: active_device.user_id).first
            not_found!(USER_NOT_FOUND, "User: " + active_device.user_id.to_s) unless user

            # Set firmware_status to 0 (firmware updated) for the device 
            active_device.firmware_status = Settings.success_update_firmware_status

            if ( params[:version] && (active_device.firmware_version != params[:version]) )

              active_device.firmware_version = params[:version] ;
              sendNotification = true ;

            end

            active_device.firmware_time = nil;
            active_device.save!

            # Sends notification (message : success firware update
            # Convert Alert Type from int to String
            send_notification(user,active_device,EventType::SUCCESS_FIRMWARE_EVENT.to_s)  if sendNotification ;

            # verify that firmware is critical or not
            criticalfirmware = ActionConfig.where(:action_name => ActionConfiguration::CRITICAL_FIRMWARE_VERSION,:device_model_id => active_device.device_model_id).pluck(:action_value) ;

            if criticalfirmware.include? active_device.firmware_version

              status ActionConfiguration::CRITICAL_FIRMWARE_VERSION_STATUS_CODE
              Settings.camera_service.set_firmware_version_response

            else

              status 200
              Settings.camera_service.set_firmware_version_response

            end
          end
        # Complete Query :- success_update

        # Query :- action=command&command=updating_firmware
        when "updating_firmware"
        # action=command&command=updating_firmware

            active_device = authenticated_device ;

            user = User.where(id: active_device.user_id).first
            not_found!(USER_NOT_FOUND, "User: " + active_device.user_id.to_s) unless user

            active_device.firmware_status = Settings.updating_firmware_status
            active_device.firmware_time  = Time.now.utc;
            active_device.save!

            # Sends notification (message : Updating firmware)
            send_notification(user,active_device,EventType::UPDATING_FIRMWARE_EVENT.to_s);
            Settings.camera_service.updating_firmware_response

        # End of Query :- "updating_firmware"

        # Query :- action=command&command=set_access_token&value=xxxxxxxxxxxxxxx
        when "set_access_token"
        # command=set_access_token&value=xxxxxxxxxxxxxxx

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"

          elsif params[:value].nil? || params[:value].is_empty?
            status PARAMETER_MISSING
            "Parameter missing: value"

          else

            active_device = authenticated_device ;
            active_device.access_token = params[:value]
            active_device.save!

            Settings.camera_service.set_access_token_response
          end
        # End of Query :- set_access_token.
        
        # Query :- action=command&command=get_current_time
        when "get_current_time"
          # command=get_current_time
          Time.now.utc
        # Complete Query :- "get_current_time"

        # Query :- action=command&command=ping
        when "ping"
          # command=ping
         status 200
        # Complete Query :- "ping"


        # Query :- action=command&command=get_rtmp_ip
        when "get_rtmp_ip"
        # command=get_rtmp_ip

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"

          else
            active_device = authenticated_device ;
            region_code = HubbleConfiguration::DEFAULT_REGION_CODE ;

            if active_device.device_location
              region_code = active_device.device_location.remote_region_code;
            end
            device_model = DeviceModel.where(id: active_device.device_model_id).first
            case device_model.model_no
            when *GeneralSettings.connect_settings[:model] #for connect camera
              http_url = "http://" + GeneralSettings.connect_settings[:rtmp_loadbalancer_ip]
              loadbalancer_uri = Settings.load_balancer_url % [http_url,GeneralSettings.connect_settings[:rtmp_loadbalancer_port],region_code];
            else #for normal hubble cameras
              # Get Wowza Load Balancer
              if(Settings.urls.wowza_server[0..3].upcase == "HTTP")
                loadbalancer_uri = Settings.load_balancer_url % [Settings.urls.wowza_server,Settings.urls.wowza_http_port,region_code] ;
              else
                http_url = "http://" + Settings.urls.wowza_server
                loadbalancer_uri = Settings.load_balancer_url % [http_url,Settings.urls.wowza_http_port,region_code] ;
              end
            end
            
            Rails.logger.debug "Model no: #{device_model.model_no}  RTMP REQUEST URL: #{loadbalancer_uri}"
            begin

              Timeout::timeout(Settings.time_out.wowza_server_timeout) do 

                response =  HTTParty.get(loadbalancer_uri)
                status 200
                rtmp_ip= "rtmp_ip="+response.split('=').last
              end

              rescue Timeout::Error
                internal_error!(TIMEOUT_ERROR,"Timeout occured in connecting wowza load balancer server ")     #has to move all internal error messages to config file

              rescue Errno::ETIMEDOUT
                internal_error!(TIMEOUT_ERROR,"HTTP Timeout occured  in connecting wowza load balancer server  ")

              rescue Errno::ECONNREFUSED => e
                internal_error!(TIMEOUT_ERROR,"Wowza load balancer server not responding");

              rescue SocketError => exception
                internal_error!(TIMEOUT_ERROR,"Server connnection occured");
            end
          end
        # Complete Query :- "get_rtmp_ip"

        # Query :- action=command&command=get_attribute
        when "get_attribute"
        # command=get_extended_attribute&key=xxx

          if params[:auth_token].nil?
            status PARAMETER_MISSING
            "Parameter missing: auth_token"

          elsif params[:key].nil? || params[:key].is_empty?
            status PARAMETER_MISSING
            "Parameter missing: key"  

          else
            active_device = authenticated_device ;
            extended_attribute = active_device.extended_attributes.where(key: params[:key]).first

            status 200
            extended_attribute.value if extended_attribute
          end

        # Query :- action=command&command=set_camera_setting
        when "set_camera_setting"
          if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"
          else
            CameraServiceAPI.new.set_camera_setting(self, authenticated_device, params);
            status 200
            return ""
          end
        # Complete Query :- "set_camera_setting"

        # Query :- action=command&command=get_camera_setting
        when "get_camera_setting"
          if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"
          else
            result = CameraServiceAPI.new.get_camera_setting(authenticated_device);
            status 200
            result
          end
        # Complete Query :- "get_camera_setting"

        else
          # Other commands are not supported
          status 601
          "Invalid command passed."
        end

      end
    end

  end
  # Completed Cameraservice query for GET Method

  # Query :- BMS/cameraservice?
  # Method :- POST
  # Description :- All API are belongs to device.
  resource :cameraservice do

    post  do

      # check that action is given us "command"
      if params[:action] != "command"
        status 601
        "Invalid action..."

      else

        # check that which query command present in parameter
        case params[:command]

          # Query :- action=command&commad=update_cam_ip
          when "update_cam_ip1"
          # command=update_cam_ip&mac=987654321012&fwversion=<XX.YY.ZZ>

            status 200
            # Get remote IP address
            ip_address = get_ip_address ;

            if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"

            else

              active_device = authenticated_device ;

              # check that IP address validation.
              if params[:local_ip]
                if  params[:local_ip].length < 7 || !(IPAddress.valid? params[:local_ip])
                  status INVALID_PARAMETER_FORMAT
                  return "Invalid IP Address format"
                end
              end

              # Camera should update firmware version once it is restarted.
              if params[:fwversion]
                if Gem::Version.new(params[:fwversion]) != Gem::Version.new(active_device.firmware_version)
                  active_device.firmware_version = params[:fwversion] ;
                  active_device.save! ;
                end
              end

              # device firmware did not support new version of API Server.
              location = active_device.device_location ;
              unless location
                  active_device.device_location = DeviceLocation.new;
                  active_device.save! ;
                  location = active_device.device_location;
              end

              if ( (location.remote_ip != ip_address) || ( params[:local_ip] && location.local_ip != params[:local_ip]) )
                location.remote_ip = ip_address ;
                location.remote_iso_code = get_country_ISOCode(ip_address);
                location.remote_region_code = get_LoadBalancer_regionCode(location.remote_iso_code);
                location.local_ip = params[:local_ip] if params[:local_ip]
                location.save!
              end
              

              if (supportnewVersion!(active_device.registration_id[2..5],active_device.firmware_version))

                # device firmware supports new version of API server.

                # Send critical command to device.
                Thread.new {

                  begin

                    active_device.device_critical_commands.each do |critical_command|
                      response = send_command_over_stun(active_device, critical_command.command);
                      critical_command.destroy if (response && response[:device_response][:device_response_code] == 200)
                    end

                    rescue Exception => exception
                    ensure
                      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                      ActiveRecord::Base.clear_active_connections! ;
                  end
                }

              end # End of SupportNewversion condition

              # ToDo :- Work around solution.
              # We have found that stun channel is broken between stun server & device. So, Device will send update cam ip
              # request every 10 minutes and Server will check that stun channel is broken or not. if stun channel is not broken
              # then send status as 200 otherwise send status as 709.
              if(is_device_available_cache_status(active_device.mac_address))

                Settings.camera_service.upate_ip_response % [ip_address , active_device.registration_id , params[:local_ip]]

              else
                status HubbleHttpStatusCode::STUN_LIBRARY_CRASHED_CODE
                Settings.camera_service.upate_ip_response % [ip_address , active_device.registration_id , params[:local_ip]]
              end
              # todo cameraservice line:1481
            end
          # Complete Query :- update_cam_ip1

          # Query :- action=command&command=set_attribute
          when "set_attribute"
          # command=set_extended_attribute&key=xxx&value=xxxx

            if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"

            elsif params[:key].nil? || params[:key].is_empty?
              status PARAMETER_MISSING
              "Parameter missing: key"

            elsif params[:value].nil? || params[:value].is_empty?
              status PARAMETER_MISSING
              "Parameter missing: value "

            elsif ExtendedAttribute.invalid_key(params[:key])
              status INVALID_PARAMETER_FORMAT
              "Invalid key format"

            elsif params[:key].length < 1 || params[:key].length > 25
              status INVALID_PARAMETER_FORMAT
              "Invalid key length"

            else
              # Get authentication device
              active_device = authenticated_device ;

              active_user = User.where(id: active_device.user_id).first
              not_found!(USER_NOT_FOUND, "User: " + active_device.user_id.to_s) unless active_user

              extended_attribute = active_device.extended_attributes.where(key: params[:key]).first
              extended_attribute = active_device.extended_attributes.new unless extended_attribute

              begin 

                extended_attribute.device_attribute_set_by_device(active_user, active_device, params[:key], params[:value]) ;

                status 200
                Settings.camera_service.extended_attribute_set_response ;

              rescue ActiveRecord::RecordInvalid => recordInValid

                Rails.logger.error(recordInValid.to_s) ;

                status HTTP_CLIENT_CONFLICT_ERROR_CODE
                Settings.camera_service.extended_attribute_failed_response ;

              end

            end
          # Complete Query :- "set_attribute"

          # Query :- action=command&command=registration_details
          when "registration_details"

            if params[:udid].nil?
              status PARAMETER_MISSING
              "Parameter missing: udid"

            elsif params[:local_ip].nil? || params[:local_ip].is_empty?
              status PARAMETER_MISSING
              "Parameter missing: local_ip"

            elsif params[:netmask].nil? || params[:netmask].is_empty?
              status PARAMETER_MISSING
              "Parameter missing: netmask"

            elsif params[:gateway].nil? || params[:gateway].is_empty?
              status PARAMETER_MISSING
              "Parameter missing: gateway"

            else

              # check that IP address validation.
              if params[:local_ip]

                if  params[:local_ip].length < 7 || !(IPAddress.valid? params[:local_ip])
                  status INVALID_PARAMETER_FORMAT
                  return "Invalid IP Address format"
                end

              end

              if ( params[:udid].length != Settings.registration_id_length)

                 status INVALID_PARAMETER_FORMAT
                 return "Invalid UDID" 

              end

              device_model_no    = params[:udid][2..5];
              device_mac_address = params[:udid][6..17];

              device_model = DeviceModel.where(model_no: device_model_no).first ;

              unless device_model

                status MODEL_NOT_FOUND
                return "Not Found: #{device_model_no} "

              end

              if device_model.udid_scheme == "physical"

                # Get device information from Device Master
                device_master = DeviceMaster.where(registration_id: params[:udid], mac_address: device_mac_address).first

                # device is not present in system
                unless device_master

                  status REGISTRATION_ID_NOT_FOUND
                  return "#{params[:udid]} not found"

                end

              end

              begin

                registration_details = RegistrationDetail.where(registration_id: params[:udid],mac_address: device_mac_address ).first ;

                registration_details = RegistrationDetail.new unless registration_details ;


                registration_details.registration_id = params[:udid] ;
                registration_details.mac_address = device_mac_address ;
                registration_details.local_ip = params[:local_ip] ;
                registration_details.net_mask = params[:netmask] ;
                registration_details.gateway = params[:gateway] ;
                registration_details.remote_ip =  get_ip_address ;
                registration_details.expire_at = registration_details.get_registration_detail_expire_time ;

                registration_details.save! ;

                rescue Exception => exception
                  status DATABASE_VALIDATION_ERROR
                  return "Database validation Error"
              end

              status 200
              return "Registration Details Updated"

            end
          # Complete Query :- "registration_details"

        when "generate_upload_policy"
          if params[:auth_token].nil?
              status PARAMETER_MISSING
              "Parameter missing: auth_token"
          else
            active_device = authenticated_device

            policy_document = CameraServiceAPI.new.get_policy_document(active_device.registration_id,Time.now.utc+Settings.policy_expiry_days.days)
            
            policy = Base64.encode64(policy_document.to_json).gsub("\n","")
            
            signature = Base64.encode64(
                    OpenSSL::HMAC.digest(
                        OpenSSL::Digest::Digest.new('sha1'), 
                        Settings.aws_secret_access_key, policy)
                    ).gsub("\n","")

            status 200
            "policy="+policy+"&signature="+signature+"&key_id="+Settings.aws_access_key_id

          end    

        else

          # Other commands are not supported
          status 601
          "Invalid command passed."

        end

      end
    end

  params do
    requires :auth_token, :type => String
  end
  
  get "subscription" do
    active_device = authenticated_device
    status 200
    "subscription: #{active_device.plan_id}"
  end
  
  end # Resource CameraService POST Method completed

  def get_policy_document(registration_id,expiry)
    conditions = []
    bucket = {
                :bucket => Settings.s3_bucket_name
              }
    
    # Policy defining the folder path should start with
    key_condition = ["starts-with", "$key", "devices/"+registration_id]

    # The access control policy
    acl_condition = {:acl => "private"}

    encrypt_condition = {"x-amz-server-side-encryption" => "AES256"}

    content_type = ["starts-with", "$Content-Type", ""]

    content_length = ["content-length-range", 0, Settings.content_length_limit]

    conditions << bucket << key_condition << acl_condition << encrypt_condition << content_type << content_length 

    policy_document = {
      :expiration => expiry,
      :conditions => conditions
    }
  end  

  def is_child_event?(alert)
    flag = false
    alert = alert.to_i
    if (alert == EventType::DOOR_MOTION_DETECT_EVENT or alert == EventType::PRESENCE_DETECT_EVENT)
      flag = true
    end
    return flag
  end

  # This method persists all the camera setting in DB. 
  def set_camera_setting(self_obj, active_device, params)
    params.each { |key, value| 
      unless EXTENDED_ATTRIBUTE_TO_EXCLUDE.include? key
        extended_attribute = active_device.extended_attributes.find_or_create_by_key(key)
        extended_attribute.device_attribute_set_by_user(key, value)
        self_obj.send_command(CMD_ATTR_UPDATE,active_device,key,value)               
      end
    }
  end

  # This method returns all the camera setting from DB. 
  def get_camera_setting(active_device)
    array_extended_attributes = active_device.extended_attributes
    result = ""
    format = "%s=%s,"
    array_extended_attributes.each do |extended_attributes|
      result << format % [extended_attributes.key, extended_attributes.value]
    end

    if result.length >0 
      result.chop! # removing last character ','
    end

    return result
  end

end
# End of CameraService API
