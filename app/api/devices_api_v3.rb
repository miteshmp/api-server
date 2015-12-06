require 'json'
require 'grape'
require 'error_format_helpers'
require 'ip'
require 'timeout'
require 'thread'

# Class :- DevicesAPI_v3
# Description :- This file contains all device related API for version 'v3'
#
class DevicesAPI_v3 < Grape::API

  include Audited::Adapters::ActiveRecord
  formatter :json, SuccessFormatter
  format :json
  default_format :json
 
  # Version 'v3' :- Used for all below API
  version 'v3', :using => :path, :format => :json

  # Helpers method are defined
  helpers AwsHelper
  helpers RecurlyHelper
  helpers HubbleHelper
  helpers MandrillHelper
  helpers DeviceCommandHelper
  helpers DeviceEventHelper
  before do
    $gabba = Gabba::Gabba.new(Settings.google_analytics_tracker, Settings.google_analytics_domain)
  end 
   
  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :devices do



    # Query :- Get list of all devices. (Admin access needed)
    # Method :- GET
    # Parameters :-
    #         q :- Search Parameter
    #       page:- Page Number
    #       size:- Size per page
    # Response :-
    #         Return all device info
    desc "Get list of all devices. (Admin access needed) "

    params do
      optional :q, :type => Hash, :desc => "Search parameter" 
      optional :own, :type => Boolean, :desc => "Boolean parameter, if set to true only own devices can be accessed.Default value is false"
      optional :list_type, :type => String, :desc => "Allowed values are \"parent\" or \"child\""
      optional :page, :type => Integer
      optional :size, :type => Integer
       
    end

    get do

      list =nil
      availability_threads = [] ;

      active_user = authenticated_user ;
      params[:size] = Settings.default_page_size unless params[:size] ;
      is_admin=params[:own] ==nil || params[:own] == false
      
      if is_admin

        forbidden_request! unless active_user.has_authorization_to?(:read_any, Device) ;
        list = params[:q] ? Device.search(params[:q]).result(distinct: true) : Device.includes(:device_location, :device_settings).paginate(:page => params[:page], :per_page => params[:size]) ;
        
      else
          
        fileterHash =  params[:q] ? params[:q] : Hashie::Mash.new 
        fileterHash[:user_id_eq]=active_user.id

        if params[:list_type] != nil

          if params[:list_type]== "parent"

            fileterHash[:parent_id_null]=true
            list = Device.search(fileterHash).result(distinct: true).includes(:device_location, :device_settings) .paginate(:page => params[:page], :per_page => params[:size]);

          elsif params[:list_type]== "child"

            fileterHash[:parent_id_not_null]=true
            list = Device.search(fileterHash).result(distinct: true).includes(:device_location, :device_settings) .paginate(:page => params[:page], :per_page => params[:size]);
            
          else

            list = Device.search(fileterHash).result(distinct: true).includes(:device_location, :device_settings).paginate(:page => params[:page], :per_page => params[:size]) ;
            
          end

        else
          list =  Device.search(fileterHash).result(distinct: true).includes(:device_location, :device_settings).paginate(:page => params[:page], :per_page => params[:size]) ;

        end
        
      end  

      if !is_admin

        s3 = AWS::S3.new
        obj = s3.buckets[Settings.s3_bucket_name].objects['hubble.png'] ;
        default_url =  obj.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s
        # created thread array
        s3 = AWS::S3.new
        obj = s3.buckets[Settings.s3_bucket_name].objects['hubble.png'] ;
        default_url =  obj.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s

        # created thread array
       
        list.each do |device|

          availability_threads << Thread.new {

            begin

              deviceSnapStatus = device_logo_is_exist!(device.registration_id);

              if deviceSnapStatus[:status]
                device.snaps_url = deviceSnapStatus[:logo_url];
                device.snaps_modified_at = deviceSnapStatus[:snaps_modified_at];

              else

                device.snaps_url = default_url ;
                device.snaps_modified_at = nil;

              end

              device.is_available = is_device_available_cache_status(device.mac_address);

            rescue Exception => exception
            ensure
              # Active record connections open when Thread is created
              ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
              ActiveRecord::Base.clear_active_connections! ;
            end
          }

        end
        # wait until all thread finished all task.
        availability_threads.each { |thr| thr.join }
         
      end
      present list, with: Device::Entity, type: :full
    end
  
    # Complete Query:- Device Registration

    # Query :- List of all devices that belong to current user.
    # Method :- GET
    # Parameters :-
    #     None
    # Response :-
    #         Return all devices which are belongs to current User

    desc "List of all devices that belong to current user. "

    get 'own' do

      active_user = authenticated_user ;

      status 200

      list = active_user.devices.includes(:device_settings,:device_location) ;

      s3 = AWS::S3.new
      obj = s3.buckets[Settings.s3_bucket_name].objects['hubble.png'] ;
      default_url =  obj.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s

      # created thread array
      availability_threads = [] ;

      list.each do |device|
      
        #        availability_threads << Thread.new {
        
        begin
          
          device_model = DeviceModel.where(id: device.device_model_id).first
          case device_model.model_no
          when *GeneralSettings.connect_settings[:model] #for connect camera
            #check for hubble.png or hubble.jpg image first preference hubble.jpg image exist
            Rails.logger.debug(":file_server_host:#{GeneralSettings.connect_settings[:s3_device_image_path_1]}")
            image_url_1 = GeneralSettings.connect_settings[:s3_device_image_path_1]+device.registration_id+"/image.png"
            file_server_response=nil
            begin
              file_server_response=RestClient::Request.execute(:method => :get, :url =>image_url_1,:headers => {'Content-Type' => 'application/json'})
            rescue Exception => err
              Rails.logger.warn("caught exception : #{err.inspect}")
            end
            if !file_server_response.nil? && file_server_response.code.eql?(200)
              device.snaps_url = image_url_1
            else
              device.snaps_url = default_url
            end
            device.snaps_modified_at = nil;
          else #for normal hubble cameras
            deviceSnapStatus = device_logo_is_exist!(device.registration_id);
            
            if deviceSnapStatus[:status]
              device.snaps_url = deviceSnapStatus[:logo_url];
              device.snaps_modified_at = deviceSnapStatus[:snaps_modified_at];
              
            else
              
              device.snaps_url = default_url ;
              device.snaps_modified_at = nil;
              
            end
          end
          device.is_available = is_device_available_cache_status(device.mac_address)
          
        rescue Exception => exception
          Rails.logger.warn("caught exception : #{exception.inspect}  message : #{exception.message}")
        ensure
          # Active record connections open when Thread is created
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end
        #      }

      end
      # wait until all thread finished all task.
      availability_threads.each { |thr| thr.join }
      
      present list, with: Device::Entity, type: :full
    end
    
    
    
    desc "Get the list of events. ", {
      :notes => <<-NOTE
      If event_code is specified before_start_time and alerts are not considered.
      start_time is having more preference than page,size.
      If page is 2 and size is 5 , It returns maximum 5 events of page 2.

      NOTE
    }
    params do
      optional :before_start_time, :desc => "Example format : 2013-12-20 20:10:18 (yyyy-MM-dd HH:mm:ss)."
      optional :event_code, :type => String, :desc => "Event code."
      optional :alerts, :desc => "Comma separated list of alerts. Example : 1,2,3,4"
      optional :page, :type => Integer, :desc => "Page number."
      optional :size, :type => Integer, :desc => "Number of records per page (defaut 10)."
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    get ':registration_id/events' do
      active_user = authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless active_user.has_authorization_to?(:list, device)
      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      status 200
      params[:size] = Settings.default_page_size unless params[:size] ;
      events = [] ;
      device_events = [] ;
      alerts = params[:alerts].split(',') if params[:alerts]
      data_period = 0
      plan_period = PlanParameter.joins(:subscription_plan).where("subscription_plans.plan_id = ?", device.plan_id).where(parameter: PLAN_PARAMETER_DATA_RETENTION_FIELD).pluck(:value).first
      if (plan_period.present?)
        data_period = plan_period.to_i
      end
      if params[:event_code]
        device_events = DeviceEvent.where("event_code like ?","#{params[:event_code]}%").paginate(:page => params[:page], :per_page => params[:size])
      elsif (params[:before_start_time] && params[:alerts])
        device_events = DeviceEvent.where("time_stamp <= ? AND alert in (?) AND device_id = ?",params[:before_start_time],alerts,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif params[:before_start_time]
        device_events = DeviceEvent.where("time_stamp <= ? AND device_id = ?",params[:before_start_time],device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif params[:alerts]
        device_events = DeviceEvent.where("alert in (?) AND device_id = ?",alerts,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      else
        device_events = DeviceEvent.where(device_id: device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      end
      device_model = DeviceModel.where(id: device.device_model_id).first
      case device_model.model_no
      when *GeneralSettings.connect_settings[:model] #for connect camera
        Rails.logger.info("Device event len : #{device_events.size}")
        sorted_events = collect_sorted_events(device_events, data_period)
      else #for normal hubble cameras
        sorted_events = collect_events_data(device_events, data_period)
      end
      {
        :total_events => device_events.count,
        :total_pages => device_events.total_pages,
        :events => sorted_events.reverse
      }
      
    end

    # Returns a list of events from all of the user's devices
    desc "Get the list of events from all devices that belong to the user. ", {
      :notes => <<-NOTE
      If event_code is specified before_start_time and alerts are not considered.
      start_time has more preference than page,size.
      If page is 2 and size is 5 , It returns maximum 5 events of page 2.

      NOTE
    }
    params do
      optional :reg_ids, :desc => "Comma separated list of registration ids"
      optional :before_start_time, :desc => "Example format : 2013-12-20 20:10:18 (yyyy-MM-dd HH:mm:ss)."
      optional :event_code, :type => String, :desc => "Event code."
      optional :alerts, :desc => "Comma separated list of alerts. Example : 1,2,3,4"
      optional :page, :type => Integer, :desc => "Page number."
      optional :size, :type => Integer, :desc => "Number of records per page (defaut 10)."
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    get 'events' do
      active_user = authenticated_user
      status 200
      params[:size] = Settings.default_page_size unless params[:size] ;
      events = [] ;
      device_events = [] ;
      alerts = params[:alerts].split(',') if params[:alerts] ;
      registration_ids = params[:reg_ids].split(',') if params[:reg_ids]
      data_period = 0
      # We select the max data_period of all devices of a user
      devices_plans = active_user.devices.pluck(:plan_id)
      plan_period = PlanParameter.joins(:subscription_plan).where("subscription_plans.plan_id in (?)", devices_plans).where(parameter: PLAN_PARAMETER_DATA_RETENTION_FIELD).pluck(:value).first
      if (plan_period.present?)
        data_period = plan_period.to_i
      end

      if params[:event_code]
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND event_code like ?","#{params[:event_code]}%").paginate(:page => params[:page], :per_page => params[:size])
      elsif (params[:reg_ids] && params[:before_start_time] && params[:alerts])
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND time_stamp <= ? AND alert in (?) AND devices.registration_id in (?)",params[:before_start_time],alerts,registration_ids).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif (params[:reg_ids] && params[:before_start_time])
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND time_stamp <= ? AND devices.registration_id in (?)",params[:before_start_time],registration_ids).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif (params[:reg_ids] && params[:alerts])
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND alert in (?) AND devices.registration_id in (?)",alerts,registration_ids).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif (params[:before_start_time] && params[:alerts])
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND time_stamp <= ? AND alert in (?)",params[:before_start_time],alerts).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif params[:reg_ids] 
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND devices.registration_id in (?)",registration_ids).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif params[:before_start_time]
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND time_stamp <= ?",params[:before_start_time]).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif params[:alerts]
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL AND alert in (?)",alerts).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      else
        device_events = DeviceEvent.includes(:device).where(:device => {:user_id => active_user.id}).where("device_events_1.deleted_at IS NULL").order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size]).select("device_events_1.*, devices.id, devices.registration_id")
      end  
      
      case active_user.tenant_id.to_s
      when *GeneralSettings.connect_settings[:tenant_id] #for connect camera
        Rails.logger.info("Device event len : #{device_events.size}")
        sorted_events = collect_sorted_events(device_events, data_period)
      else #for normal hubble cameras
        sorted_events = collect_events_data(device_events, data_period)
      end
      {
        :total_events => device_events.count,
        :total_pages => device_events.total_pages,
        :events => sorted_events.reverse
      }
    end

    # Query :- Create a Sessiom for Devcie which belongs to Current user
    # Method :- POST
    # Parameters :-
    #         client_type   :- Client type
    #         client_nat_ip :- NAT IP Address
    #         client_nat_port :- NAT IP port
    # Response :-
    #         Return session informaton to application.
    
    desc "Create a session for a device that belongs to current user"

    params do

      requires :client_type, :desc => "Type of client. Either IOS,ANDROID or BROWSER"
      optional :client_nat_ip, :validate_ip_address_format => true, :desc => "NAT IP address"
      optional :client_nat_port, :validate_port_format => true, :type => Integer,:desc => "NAT IP port"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end

    post ':registration_id/create_session' do
      
      active_user = authenticated_user ;

      device = Device.where(registration_id: params[:registration_id]).includes(:device_location).first ;

      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
      forbidden_request! unless active_user.can_access_device?(:create_session, device,active_user ) ;

      bad_request!(MAC_ADDRESS_NULL,"Mac address is null") unless device.mac_address ;
      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive" ;

      device.save!
      device_model = DeviceModel.where(id: device.device_model_id).first
      relay_rtmp_ip = get_wowza_rtmp_address(device.device_location.remote_region_code,device_model.model_no) ;


      # check that device support new version server or not
      if supportnewVersion!(device.registration_id[2..5],device.firmware_version) 

        case params[:client_type].downcase

        when "android", "ios"
          command = Settings.camera_commands.get_session_key_mode_any_command % [params[:client_nat_ip] , params[:client_nat_port], relay_rtmp_ip, device.generate_stream_name() ]

        when "browser"
          command = Settings.camera_commands.get_session_key_mode_rtmp % [params[:client_nat_ip],params[:client_nat_port], relay_rtmp_ip, device.generate_stream_name() ]

        else

          # Send bad request for invalid client type with error code "invalid_client_type :- 4006"
          bad_request!(INVALID_CLIENT_TYPE, "Invalid client type.") ;
        end

      else
        # device did not support new version of server.

        case device.mode.downcase
          # mode information is available in device table
        when "upnp"

          case params[:client_type].downcase

          when "android", "ios"
            command = Settings.camera_commands.get_session_key_mode_any_command_oldversion % [relay_rtmp_ip] ;

          when "browser"
            command = Settings.camera_commands.get_session_key_mode_rtmp_oldversion % [relay_rtmp_ip];

          else
            bad_request!(INVALID_CLIENT_TYPE, "Invalid client type.") ;

          end

        when "relay"

          command = Settings.camera_commands.get_session_key_mode_rtmp_oldversion % [relay_rtmp_ip] ;

        when "stun"

          command = Settings.camera_commands.get_session_key_mode_rtmp_oldversion % [relay_rtmp_ip];

          # todo: later throw error telling user to use the other method
        else
          # todo : throw error invalid mode
        end

      end

      # send the get session key command to device
      response = send_command_over_stun(device,command);

      # response format
      # get_session_key: error=ERROR_NUMBER,session_key=<RTSP URL using NAT IP &PORT> ,talk_back_port = <talk_back_port>, mode=p2p_stun_rtsp
      # get_session_key: error=ERROR_NUMBER,session_key=<RTSP URL> ,talk_back_port = <talk_back_port>, mode=p2p_upnp_rtsp

      if supportnewVersion!(device.registration_id[2..5],device.firmware_version) 

        # check that device support new version server or not
        internal_error_with_data!(UNABLE_TO_CREATE_SESSION, ERRORS[response[:device_response][:device_response_code]], response) unless response[:device_response][:device_response_code] == 200 ;
        parsed_device_response = nil ;

        begin

          parsed_response = response[:device_response][:body] ;
          if parsed_response
            # it is require that we should move extra response character
            # Response from device after this :- "error=ERROR_NUMBER,session_key=<RTSP URL using NAT IP &PORT> ,talk_back_port = <talk_back_port>, mode=p2p_stun_rtsp"
            parsed_response = parsed_response.gsub("get_session_key: ",'');
          end
          # parse the response and get the key value pairs in a hash
          parsed_device_response = Rack::Utils.parse_nested_query(parsed_response.to_s,',')

        rescue Exception => NoMethodError
          internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Error parsing response from the device. The response from device is not in expected format.", response)
        end

        internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. There is an error reported by the device.", response) unless parsed_device_response["error"] == "200"

        Thread.new {

          begin

            event_log = active_user.event_logs.new ;
            event_log.event_name = EventLogMessage::CREATE_SESSION ;
            event_log.event_description = parsed_device_response["mode"] if parsed_device_response["mode"] ;
            event_log.remote_ip = get_ip_address ;
            event_log.time_stamp = Time.now.utc ;
            event_log.registration_id = params[:registration_id] ;
            event_log.user_agent = get_user_agent ;
            event_log.save!

          rescue Exception => exception
          ensure
            ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
            ActiveRecord::Base.clear_active_connections! ;
          end

        }

        if ( parsed_device_response["mode"] && parsed_device_response["mode"].casecmp(HubbleStreamMode::RELAY_RTMP_STREAM_MODE) == 0 )

          device.save_stream_name(parsed_device_response["session_key"]);

        end

        url = DevicesAPI_v2.new.modify_url(parsed_device_response["session_key"])

        status 200
        {
          :url => url,
          :talk_back_port => parsed_device_response["talk_back_port"],
          :mode => parsed_device_response["mode"]
        }

      else 
        # device does not support  new version.
        begin

          parsed_response = response[:device_response][:body]

          # split all the sections
          arr2 = parsed_response.split(",") ;

          # get the error code
          status_code = arr2[0].split("=")[1] ;

          # get the session key and mode
          session_key = arr2[1].split("=")[1] ;
          mode = arr2[2].split("=")[1] ;

        rescue Exception => NoMethodError
          internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Error parsing response from the device. The response from device is not in expected format.", response)
        end

        #internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. There is an error reported by the device.", response) unless status_code == "200" 

        case mode

        when "p2p_upnp_rtsp", "1"


          location = device.device_location ;
          remote_ip = location.remote_ip ;
          remote_port_1 = location.remote_port_1 ;
          remote_port_2 = location.remote_port_2 ;
          remote_port_3 = location.remote_port_3 ;
          remote_port_4 = location.remote_port_4 ;
          registeredration_id = device.registration_id ;


          if (remote_ip.nil? || remote_port_1.nil? || remote_port_4.nil?)
            internal_error_with_data!(DEVICE_LOCATION_NOT_UPDATED, "Unable to establish an RTSP session. Device location is not updated.",  response )
          end

          Thread.new {

            begin
              event_log = active_user.event_logs.new ;
              event_log.event_name = EventLogMessage::CREATE_SESSION ;
              event_log.event_description = mode if mode ;
              event_log.remote_ip = get_ip_address ;
              event_log.time_stamp = Time.now.utc ;
              event_log.registration_id = params[:registration_id] ;
              event_log.user_agent = get_user_agent ;
              event_log.save!

            rescue Exception => exception
            ensure
              ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
              ActiveRecord::Base.clear_active_connections! ;
            end
          }

          status 200
          $gabba.event(Settings.catergory_devices, "Session","RTSP")
          {
            :url => Settings.p2p_upnp_rtsp_url % [registration_id, session_key, remote_ip, remote_port_1.to_s],
            :talk_back_port => remote_port_4,
            :mode => mode
          }

        when "relay_rtmp", "2"

          Thread.new {

            begin

              event_log = active_user.event_logs.new ;
              event_log.event_name = EventLogMessage::CREATE_SESSION ;
              event_log.event_description = mode if mode ;
              event_log.remote_ip = get_ip_address ;
              event_log.time_stamp = Time.now.utc ;
              event_log.registration_id = params[:registration_id] ;
              event_log.user_agent = get_user_agent ;
              event_log.save!

            rescue Exception => exception
            ensure
              ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
              ActiveRecord::Base.clear_active_connections! ;
            end
          }

          # it is required that we should store macaddress as stream name in database, so it will used to 
          # send "close session" query
          device.save_stream_name(session_key);

          url = DevicesAPI_v2.new.modify_url(session_key)

          status 200
          $gabba.event(Settings.catergory_devices, "Session","Relay RTMP") 
          {
            :url => url,
            :mode => mode
          }

        else
          internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Invalid response received from device.", response)

        end
      end # end of supportNewversion condition.

    end
    # Complete Query :- Create a Sessiom for Devcie which belongs to Current user
  
    
    
    desc "Delete device events between time interval", {
      :notes => <<-NOTE
       Input UTC Date will be converted to device timezone date for processing
       time_from,time_to format: '%Y-%m-%dT%H:%M:%S%z'
       Example : 2001-02-03T04:05:06+07:00
      NOTE
    }

    params do
      
      requires :time_from,validate_date_time_format: true, :desc => "UTC datetime format '2001-02-03T04:05:06+07:00'"
      requires :time_to,validate_date_time_format: true,:desc => "UTC datetime format like '2001-02-03T04:05:06+07:00'"
      
    end
    
    delete ':registration_id/delete_events_session' do
      active_user = authenticated_user ;
      status 200
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless active_user.has_authorization_to?(:delete_event, device)
      data_time_from=DateTime.strptime(params[:time_from],'%Y-%m-%dT%H:%M:%S%z')
      date_time_to=DateTime.strptime(params[:time_to],'%Y-%m-%dT%H:%M:%S%z')
      response=[]
      
      begin
        device_events =  device.device_events.where("event_time BETWEEN ? and ?",params[:time_from],params[:time_to]).paginate(:page => 1,:per_page=>500)
        device_events.each do |event|
          response << {
            :alert => event.alert,
            :event_code => event.event_code,
            :time_stamp => event.event_time.to_s,
          }
        end
        device_events.destroy_all
      end until device_events.empty?
      Rails.logger.warn("event len deleted :#{response.length}")
      response
    end

  end

  def modify_url(url)
    wowza_ip = url.split('://')[1].split(':')[0]
    wowza_hostname = GeneralSettings.wowza_ip_mappings[wowza_ip]
    url = url.sub(wowza_ip,wowza_hostname) if wowza_hostname # Replace wowza ip with hostname
    url = url.sub('rtmp:','rtmps:').sub('1935','443')  # Replace rtmp with rtmps and port number 1935 to 443
    return url

  end  


end
