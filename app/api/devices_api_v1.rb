require 'json'
require 'grape'
require 'error_format_helpers'
require 'ip'
require 'timeout'
require 'thread'

class DevicesAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
  formatter :json, SuccessFormatter
  format :json
  default_format :json
  version 'v1', :using => :path, :format => :json


  helpers AwsHelper
  helpers RecurlyHelper

  before do
    $gabba = Gabba::Gabba.new(Settings.google_analytics_tracker, Settings.google_analytics_domain)
  end 
   
  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :devices do
    desc "Create a device that belongs to current user. "
    params do
      requires :name, :type => String, :desc => "Name of the device"
      requires :registration_id, :type => String, :desc => "Registration Id of the device"
      requires :mode, :desc => "Device accessibility mode. (upnp OR stun OR relay) " #todo validate based on enum
      requires :firmware_version, :type => String,  :desc => "Firmware version number in the format xx.yy or xx.yy.zz."
      requires :time_zone,:type => Float, :desc => "Time Zone in the format +12.00 or -3.30 ."
      
    end
    post 'register' do
      authenticated_user

      physical_device = true
      device_model = nil
      master_batch = nil
      model_id_temp = 0
      device_master = nil
      
      invalid_parameter!("registration_id") unless params[:registration_id].length == Settings.registration_id_length
      
      device_type_code = params[:registration_id][0..1]
      device_model_no = params[:registration_id][2..5]
      device_mac_address = params[:registration_id][6..17]
      device_message = params[:registration_id][0..17]

      #first find that device is registered or not 
      registered_device = Device.where(registration_id: params[:registration_id]).first

      device_type = DeviceType.where(type_code: device_type_code).first
      not_found!(TYPE_NOT_FOUND,"DeviceType: " + device_type_code.to_s) unless device_type

      device_model = DeviceModel.where(model_no: device_model_no).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + device_model_no.to_s) unless device_model
      not_found!(TYPE_NOT_FOUND,"Invalid device type and device model combination" ) unless device_type.id == device_model.device_type_id

      unless registered_device

        device_master = DeviceMaster.where(registration_id: params[:registration_id], mac_address: device_mac_address).first
        unless device_master
          invalid_device = Device.where(mac_address: device_mac_address).first
          bad_request!(INVALID_REGISTRATION_ID, "Invalid Registration_id, mac_address already exist") if invalid_device
        end  

        if device_model.udid_scheme == "virtual"
            p "virtual"
            # Virtual device
            random_number = Base64.encode64(Digest::MD5.hexdigest(device_message))[0..7]
            invalid_parameter!("registration_id") unless random_number == params[:registration_id][18..25] 
            physical_device = false
        
        else
           p "physical"
            #Physical Device
            device_master = DeviceMaster.where(registration_id: params[:registration_id]).first
            unless device_master
        
              #TODO :- create function for "api_call_issue"
              api_call_issue = ApiCallIssues.where("api_type = ? AND error_reason = ? AND error_data = ?","device_register","registration_id_not_in_master",params[:registration_id]).first
              
              unless api_call_issue
                api_call_issue = ApiCallIssues.new
                api_call_issue.api_type = "device_register"
                api_call_issue.error_data = params[:registration_id] 
                api_call_issue.error_reason = "registration_id_not_in_master"
              end
                api_call_issue.count +=1
                api_call_issue.save!
                not_found!(REGISTRATION_ID_NOT_FOUND, "Registration id : " + params[:registration_id].to_s + " in device master") 
            end 


        end
      end 

      device_master = DeviceMaster.where(registration_id: params[:registration_id]).first
      master_batch = DeviceMasterBatch.where(id: device_master.device_master_batch_id).first if device_master 

      # checking that registered device is virtual device or not
      if registered_device
        physical_device = false unless device_master
      end 


      existing_device = current_user.devices.where(registration_id: params[:registration_id]).first
      recover_device = Device.only_deleted.where("registration_id = ?", params[:registration_id]).first unless existing_device
     if recover_device
         recover_device.recover 
         recover_device.user_id = current_user.id
      end

      device = recover_device || existing_device 

      unless device
        bad_request!(INVALID_REGISTRATION_ID, "Device is already registered with other account") if registered_device
        device = current_user.devices.new  
        device.last_accessed_date = Time.now
        device.device_model_id = device_model.id
      end 

      device.name = params[:name] if params[:name]
      device.registration_id = params[:registration_id].upcase if params[:registration_id]
      device.mac_address = device_mac_address.upcase
      device.time_zone = params[:time_zone] if params[:time_zone]
      device.plan_id = params[:plan_id]
      device.mode = params[:mode].downcase if params[:mode]

      device.firmware_version = params[:firmware_version].downcase if params[:firmware_version]

      unless existing_device  
        device.device_location = DeviceLocation.new
        device.device_capability = DeviceCapability.new
        

        setting = device.device_settings.new
        setting.key = "zoom"
        setting.value = 0
        setting = device.device_settings.new
        setting.key = "pan"
        setting.value = 0
        setting = device.device_settings.new
        setting.key = "tilt"
        setting.value = 0
        setting = device.device_settings.new
        setting.key = "contrast"
        setting.value = 0
        setting = device.device_settings.new
        setting.key = "brightness"
        setting.value = 0
        setting = device.device_settings.new
        setting.key = "melody"
        setting.value = 0
      end  

      
      
      device.plan_id = "freemium"
      device.auth_token = device.generate_token

      Audit.as_user(current_user) do  
        device.save!
      end  
      #signature will be passed in to the JavaScript code which calls Recurly.js to build the form.
      device.signature = Recurly.js.sign :subscription => { :account_code => device.registration_id }  

      create_aws_folders(device)
      $gabba.event(Settings.catergory_devices, "Register", device.registration_id)    
      status 200
      { 
        "id" => device.id,
        "registration_id" => device.registration_id,
        "auth_token" => device.auth_token,
        "signature" => device.signature,
        "plan_id" => device.plan_id
      }
    end

    desc "List of all devices that belong to current user. "
    get 'own' do
      authenticated_user
      status 200
      list = current_user.devices.includes(:device_location, :device_settings)
      s3 = AWS::S3.new  
      obj = s3.buckets[Settings.s3_bucket_name].objects['hubble.png'] 
      default_url =  obj.url_for(:read, :secure => false).to_s
      

      availability_threads = []   
      list.each do |device|  
          device.snaps_url = default_url
         availability_threads << Thread.new {  
          device.is_available = is_device_available(device)[:is_available]
        }  
      end      
      availability_threads.each { |thr| thr.join }  
      
      present list, with: Device::Entity, type: :full
    end

    desc "Get the list of all the devices shared by current user with other users" 
    params do
      optional :user_id,:type => Integer, :desc => "User id to be specified by admin ."
    end  
    get 'sharing_invitations_by_me' do
      authenticated_user
      status 200
      if params[:user_id]
        user = User.where(id: params[:user_id]).first
        not_found!(USER_NOT_FOUND, "User: " + params[:user_id].to_s) unless user
        forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceInvitation)

        device_invitations = DeviceInvitation.where(shared_by: params[:user_id])
      else
         device_invitations = DeviceInvitation.where(shared_by: current_user.id)
      end 

       present device_invitations, with: DeviceInvitation::Entity 
    end  

    desc "Get the list of all the devices shared by current user with other users" 
    params do
      optional :user_id,:type => Integer, :desc => "User id to be specified by admin ."
    end  
    get 'shared_by_me' do
      authenticated_user
      status 200
      if params[:user_id]
        user = User.where(id: params[:user_id]).first
        not_found!(USER_NOT_FOUND, "User: " + params[:user_id].to_s) unless user
        forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceInvitation)

        device_invitations = SharedDevice.where(shared_by: params[:user_id])
      else
         device_invitations = SharedDevice.where(shared_by: current_user.id)
      end 

       present device_invitations, with: SharedDevice::Entity 
    end

    desc "Get the list of all the devices shared by other users with current user" 
    params do
      optional :user_id,:type => Integer, :desc => "User id to be specified by admin ."
    end  
    get 'shared_with_me' do
      authenticated_user
      status 200
      if params[:user_id]
        user = User.where(id: params[:user_id]).first
        not_found!(USER_NOT_FOUND, "User: " + params[:user_id].to_s) unless user
        forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceInvitation)

        shared_devices = SharedDevice.where(shared_with: params[:user_id])
      else
         shared_devices = SharedDevice.where(shared_with: current_user.id)
      end 

       present shared_devices, with: SharedDevice::Entity 
    end   



    desc "Subscription cancellation."
    post ':registration_id/cancel_subscription' do
      authenticated_user

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:cancel_subscription, device)
      status 200
      begin
        account = Recurly::Account.find(params[:registration_id])
        account.subscriptions.find_each do |subscription|
          subscription = Recurly::Subscription.find(subscription.uuid)
          subscription.cancel
        end
      rescue Exception => e
        internal_error!(RECURLY_EXCEPTION, e.message) 
      end
      
      "Cancel request send to recurly"
    end

    # desc "List of all devices that are shared with current user"
    # get 'shared' do
    #   authenticated_user
    #   status 200

    #   present current_user.devices, with: Device::Entity

    # end

    # desc "List of all public devices that are accessible to current user"
    # get 'public' do
    #   authenticated_user
    #   status 200
    #   present current_user.devices, with: Device::Entity
    # end

    
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
    end  
    get ':registration_id/events' do
      authenticated_user
      status 200

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:list, device)

      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      params[:size] = Settings.default_page_size unless params[:size]

      events = []
      device_events = []
      alerts = params[:alerts].split(',') if params[:alerts]
      if params[:event_code]
          device_events = DeviceEvent.where("event_code like ?","#{params[:event_code]}%")
      elsif (params[:before_start_time] && params[:alerts])
         device_events = DeviceEvent.where("time_stamp <= ? AND alert in (?) AND device_id = ?",params[:before_start_time],alerts,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
      elsif params[:before_start_time]
        device_events = DeviceEvent.where("time_stamp <= ? AND device_id = ?",params[:before_start_time],device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size]) 
      elsif params[:alerts] 
          device_events = DeviceEvent.where("alert in (?) AND device_id = ?",alerts,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size]) 
      else 
         device_events = DeviceEvent.where(device_id: device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])  
      end
       event_threads = []
       p device_events
       semaphore = Mutex.new
       device_events.each do |event|
         event_threads << Thread.new{
          data = get_playlist_data(device,event.event_code) if (event.alert == Settings.motion_detected && event.event_code)
          alert_name = get_alert_name(event.alert)
          semaphore.synchronize {  
          events << {
            :id => event.id,
            :alert => event.alert,
            :value => event.value,
            :alert_name => alert_name,
            :time_stamp => event.time_stamp,
            :data => data
          }
        }
        }
      end
      
       event_threads.each { |thr| thr.join } 
       sorted_events = events.sort_by { |k| k[:id] }
      
      { :events => sorted_events.reverse }
    end


    desc "Get basic information of a device that belongs to current user. "
    get ':registration_id' do
      authenticated_user
      status 200

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:list, device)

      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"

      device.is_available = is_device_available(device)[:is_available]

      present device, with: Device::Entity, type: :full
    end

    # desc "Get capability information of a device that belongs to current user. "
    # get ':registration_id/capability' do
    #   authenticated_user
    #   status 200

    #   device = current_user.devices.where(registration_id: params[:registration_id]).first
    #   not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device

    #   present device.device_capability, with: DeviceCapability::Entity
    # end

    desc "Send a control command to the device that belongs to current user. ", {
      :notes => <<-NOTE
      Commands are as follows:
      -----------------

      * action=command&command=melody1
      * action=command&command=melody2
      * action=command&command=melody3
      * action=command&command=melody4
      * action=command&command=melody5
      * action=command&command=melodystop
      * action=mini_device_status
      * streamer_status
      * action=command&command=check_cam_ready
      * get_session_key&mode=any
      * get_session_key&mode=relay_rtmp
      * get_log

      NOTE
    }
    params do
      requires :command, :validate_format => true, :desc => "Command that should be sent to the device."
    end
    post ':registration_id/send_command' do
      authenticated_user
      
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.can_access_device?(:send_command, device,current_user)

      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      status 200
      send_command_over_stun(device, params[:command])
    end

    
    desc "Create a session for a device that belongs to current user"
    params do
      requires :client_type, :desc => "Type of client. Either IOS,ANDROID or BROWSER"
    end
    post ':registration_id/create_session' do
      authenticated_user

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.can_access_device?(:create_session, device,current_user)

      bad_request!(MAC_ADDRESS_NULL,"Mac address is null") unless device.mac_address
      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      
      device.save!


      case device.mode.downcase
      when "upnp"
        case params[:client_type].downcase        
        when "android", "ios"
          command = Settings.camera_commands.get_session_key_mode_any_command         
        when "browser"
          command = Settings.camera_commands.get_session_key_mode_rtmp        
        else
          bad_request!(INVALID_CLIENT_TYPE, "Invalid client type.")
        end
      when "relay"
        command = Settings.camera_commands.get_session_key_mode_rtmp  
      when "stun"
        command = Settings.camera_commands.get_session_key_mode_rtmp  
        # todo: later throw error telling user to use the other method
      else
        # todo : throw error invalid mode
      end

      # send the get session key command to device
      response = send_command_over_stun(device, command)

      # parsed_response = Rack::Utils.parse_query(response[:device_response][:body])

      # get_sesion_key: error=200,session_key=32-chars-keys,mode=p2p_upnp_rtsp
      # get_sesion_key: error=200,session_key=32-chars-stream-name,mode=relay_rtmp

      begin
        parsed_response = response[:device_response][:body]
        # split all the sections
        arr2 = parsed_response.split(",")

        # get the error code
        status_code = arr2[0].split("=")[1]

        # get the session key and mode
        session_key = arr2[1].split("=")[1]
        mode = arr2[2].split("=")[1]

      rescue Exception => NoMethodError
        internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Error parsing response from the device. The response from device is not in expected format.", response)
      end

      internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. There is an error reported by the device.", response) unless status_code == "200"

      case mode
      when "p2p_upnp_rtsp", "1"
        location = device.device_location
        remote_ip = get_remote_ip(device.mac_address)
        remote_port_1 = location.remote_port_1
        remote_port_2 = location.remote_port_2 
        remote_port_3 = location.remote_port_3 
        remote_port_4 = location.remote_port_4
        registration_id = device.registration_id

        
          internal_error_with_data!(DEVICE_NOT_AVAILABLE, "Device is not available.",  response ) if (remote_ip.nil?) 
        
        if (remote_port_1.nil? || remote_port_4.nil?) 
          internal_error_with_data!(DEVICE_LOCATION_NOT_UPDATED, "Unable to establish an RTSP session. Device location is not updated.",  response )
        end

        status 200
        $gabba.event(Settings.catergory_devices, "Session","RTSP") 
        {
          :url => Settings.p2p_upnp_rtsp_url % [registration_id, session_key, remote_ip, remote_port_1.to_s],
          :talk_back_port => remote_port_4,
          :mode => mode
        }

      when "relay_rtmp", "2"
        status 200
        $gabba.event(Settings.catergory_devices, "Session","Relay RTMP") 
        {
          :url => session_key,
          :mode => mode
        }    
      else
       internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Invalid response received from device.", response)
     end
        
   end

   desc "Close session for a devicxe"
   params do
    requires :session_id, :type => String, :desc => "Session stream id. "
   end   
   post 'close_session' do
    authenticated_user
   
    status 200

    device = Device.where(mac_address: params[:session_id]).first
    not_found!(DEVICE_NOT_FOUND, "Device: " + params[:session_id].to_s) unless device
    forbidden_request! unless current_user.has_authorization_to?(:close_session, Device)

    command = Settings.camera_commands.close_session_command
    send_command_over_stun(device, command)
   end 


   desc "Delete a device that belongs to current user. "
   params do
      optional :comment, :type => String, :desc => "Comment"
    end 
   delete ':registration_id' do
    authenticated_user
   
    device = Device.where(registration_id: params[:registration_id]).first
    not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
    forbidden_request! unless current_user.has_authorization_to?(:destroy, device)
    
    device.audit_comment = params[:comment] if params[:comment]
    Audit.as_user(current_user) do  
      device.destroy
    end  

    s3 = AWS::S3.new 
    
    bucket = AWS::S3.new.buckets[Settings.s3_bucket_name]  
    bucket.objects.with_prefix(Settings.s3_device_folder % [params[:registration_id]]).delete_all

    account = Recurly::Account.find(params[:registration_id])
    account.destroy if account 

    $gabba.event(Settings.catergory_devices, "delete",params[:registration_id])  

    status 200


    "Device deleted!"
  end


  desc "Update basic information of a device that belongs to current user. "
  params do
    optional :name, :type => String, :desc => "Device name"
    optional :time_zone,:type => Float, :desc => "Time Zone in the format +12.00 or -3.30 ."
    optional :mode,:desc => "Either of 'upnp', 'stun', or 'relay'"
    optional :firmware_version,:type => String, :desc => "Firmware version number."
  end
  put ':registration_id/basic' do
    authenticated_user

    device = Device.where(registration_id: params[:registration_id]).first
    not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device
    forbidden_request! unless current_user.has_authorization_to?(:update, device)

    invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
    device.name = params[:name] if params[:name]
    device.time_zone = params[:time_zone] if params[:time_zone]
    device.mode = params[:mode] if params[:mode]
    device.firmware_version = params[:firmware_version] if (params[:firmware_version] && !params[:firmware_version].empty?)

    status 200
    Audit.as_user(current_user) do
      device.save!
    end
    
    present device, with: Device::Entity, type: :full
  end

  desc "Update settings information of a device that belongs to current user.", {
    :notes => <<-NOTE
    The parameter settings takes an array. An example of the input is shown as follows:
    {
      "api_key" : "some_api_key......",
      "settings" : [
        {  "name" : "zoom", "value" : 8 },
        {  "name" : "pan", "value" : 9 },
        {  "name" : "tilt", "value" : 9 },
        {  "name" : "contrast", "value" : 4 }
      ]
    }

    *** This query CANNOT be executed using Swagger framework. Please use some REST client (like Postman, or RESTClient etc.)
    NOTE
  }
  params do
    requires :settings, :type => Array, :desc => "Device settings. This takes a JSON array. See query notes for example."
  end
  put ':registration_id/settings' do
    authenticated_user

    device = current_user.devices.where(registration_id: params[:registration_id]).first
    not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device

    invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
    device.device_settings = Array.new unless device.device_settings

    params[:settings].each do |item|
      name = ""
      value = ""
      begin
        name = item.name
        value = item.value
      rescue Exception => NoMethodError
        bad_request!(INVALID_DEVICE_SETTINGS_FORMAT,"Parameter 'settings' should be an array specifying keys like zoom, tilt, ... and their corresponding values.")
      end  

      setting = device.device_settings.where(key: name).first

      not_found!(INVALID_DEVICE_SETTING_KEY, "Setting: " + name.to_s) unless setting
      
      bad_request!(INVALID_DEVICE_SETTING_VALUE, "Empty value not allowed for a setting.") if value.nil? || value.to_s.is_empty?
      
      setting.value = value
      Audit.as_user(current_user) do  
        setting.save!
      end  

    end
      status 200
      present device.device_settings
  end


    desc "Check if a device (that belongs to current user) is available."     
    post ':registration_id/is_available' do
      authenticated_user

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.can_access_device?(:send_command, device,current_user)

      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      is_device_available(device)       
    end



    # desc "Request recovery for a device that belongs to current user. "
    # params do
    #   requires :recovery_type, :validate_device_recovery_type => true, :desc => "Device recovery type. Currently supports 'upnp'."
    #   requires :status, :type => String, :desc => "Device recovery status.(recoverable or unrecoverable)"
    # end
    # post ':registration_id/request_recovery' do
    #   authenticated_user

    #   device = current_user.devices.where(registration_id: params[:registration_id]).first
    #   not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device

    #   invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
    #   device.create_recovery(params[:recovery_type], get_ip_address, params[:status])
    #   #todo : do we need to check if recovery type matches the camera mode
    #   status 200
    #   "Done"
    # end


    desc "Get list of all devices. (Admin access needed) "
     params do
      optional :q, :type => Hash, :desc => "Search parameter"
      optional :page, :type => Integer
      optional :size, :type => Integer
    end
    get   do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, Device)
      

      search_result = Device.search(params[:q])
      devices = params[:q] ? search_result.result(distinct: true) : Device
      
      present devices.paginate(:page => params[:page], :per_page => params[:size])  , with: Device::Entity, type: :full
      
      end

    desc "Get list of logs. (Admin access needed) "
    get ':registration_id/logs'  do
      authenticated_user
      status 200
      
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      
      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      forbidden_request! unless current_user.has_authorization_to?(:get_logs, Device)
      get_logs(params[:registration_id])
    end

     desc "Check if device exist or not"
        get ':registration_id/check_exist' do
          device = Device.where(registration_id: params[:registration_id]).first
          
          status 200 
          device ? true : false
        end

     # desc "Reboot complete " 
     # post ':registration_id/reboot_complete' do

     #  device = Device.where(registration_id: params[:registration_id]).first
     #  not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device
      
     #  status 200
     #  "taking necessary action"
     # end 

     desc "Get audits related to a specific device "
    get ':registration_id/audit'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, Device)

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device

      status 200
      device.audits
    end



    desc "send custom notification to one or more users. "
    params do
      requires :registration_ids,:desc => "Comma seperated registration ids"
      requires :message, :type => String, :desc => "Notification message"
    end
    post 'notify_owners'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, User)
      status 200
      users = []
      
      reg_ids = params[:registration_ids].split(',')
       reg_ids.each do |id|
        device = Device.where(registration_id: id).first
        users <<  User.where(id: device.user_id).first if device
       end 
       
       users = users.uniq

       users.each do |user|
        batch_notification(user,params[:message])
       end 

       "Notification send"

    end

    desc "Upgrade or downgrade subscription plan"
        params do
          requires :plan_id, :type => String, :desc => "Either of tier1, tier2 or tier3"
        end 
        post ':registration_id/change_subscription' do
          authenticated_user

          device = Device.where(registration_id: params[:registration_id]).first
          not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device
          forbidden_request! unless current_user.has_authorization_to?(:update, device)
          
          bad_request!(CANNOT_DOWNGRADE, "Cannot be downgraded to freemium.") if params[:plan_id] == "freemium"

          uuid = nil
          account = Recurly::Account.find params[:registration_id]
          account.subscriptions.find_each do |subscription|
          uuid = subscription.uuid
        end
          status 200
           if uuid
              response = update_subscription(uuid,params[:plan_id])
              
              if response
                
                "Subscription changed successfully" 
              else
                "Change subscription failed. Subscription plan is invalid."
              end  
           else
              "This account has no billing information. Please provide billing information before creating a subscription. "
           end   
          
        end 


        desc "Upgrade subscription plan from freemium plan"
        params do
          requires :plan_id, :type => String, :desc => "Either of tier1, tier 2 or tier3"
        end 
        post ':registration_id/upgrade_plan' do
          authenticated_user

          device = Device.where(registration_id: params[:registration_id]).first
          not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device
          forbidden_request! unless current_user.has_authorization_to?(:update, device)
          
          status 200
          signature = Recurly.js.sign :subscription => { :account_code => device.registration_id }
          { 
            "id" => device.id,
            "registration_id" => device.registration_id,
            "signature" => signature,
            "plan_id" => params[:plan_id]
          }
          
        end 

        desc "Get the device capability information. "
    get ':registration_id/capability' do
      authenticated_user
      status 200

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:list, device)

      device_model = DeviceModel.where(id: device.device_model_id).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + device.device_model_id.to_s) unless device_model

      firmware_prefix = device.firmware_version
      if firmware_prefix.split('.').count == 3
        index = firmware_prefix.rindex('.')
        firmware_prefix = firmware_prefix[0..index-1]
      end  

      firmware_prefixes = device_model.device_model_capabilities.all.map(&:firmware_prefix)
      unless firmware_prefixes.empty?
          unless firmware_prefixes.include? firmware_prefix    
          
          firmware_prefixes = firmware_prefixes.collect! {|i| i.to_f}.sort
          firmware_prefix_f = firmware_prefix.to_f
          size = firmware_prefixes.length
          
          if firmware_prefix_f < firmware_prefixes[0]
            firmware_prefix= firmware_prefixes[0].to_s
          elsif firmware_prefix_f >= firmware_prefixes[size-1]
            firmware_prefix= firmware_prefixes[size-1].to_s
         else           
           i=1
           while i < size+1 do
              
              if(firmware_prefix_f >= firmware_prefixes[i-1] && firmware_prefix_f < firmware_prefixes[i])
                firmware_prefix= firmware_prefixes[i-1].to_s
                break
              end
              i = i + 1
            end
          end
        end 
      end
       
      device_model_capability = device_model.device_model_capabilities.where(firmware_prefix: firmware_prefix).first
      present device_model_capability, with: DeviceModelCapability::Entity
    end


    
    desc "Share an own device with other users"
    params do
      requires :emails, :desc => "Comma separated list of email ids."
    end  
    post ':registration_id/share' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:share, device)
      
       emails = params[:emails].split(',')
       invalid_emails = []
       sent_status = []
       data = []
       emails.each do |email|
         invalid_emails << email unless email.match(RubyRegex::Email)
       end
       invalid_request!(INVALID_EMAIL_FORMAT,"Invalid email ids: "+invalid_emails.join(",")) unless invalid_emails.empty?    
      emails.each do |email|
        device_invitation = device.device_invitations.where(shared_by: current_user.id, shared_with: email).first
        if device_invitation
          DevicesAPI_v1.send_reminder(device_invitation)
        else   
          device_invitation = device.device_invitations.new
          device_invitation.shared_by = current_user.id
          device_invitation.shared_with = email
          device_invitation.generate_invitation_key
          device_invitation.save!
          # Todo: Move to after create
          Thread.new{
            Notifier.device_share(current_user.name,email,device_invitation.invitation_key).deliver
          }
        end  
        sent_status << {
            :email => email,
            :status => Settings.email_sent_message
          }
      end  
      status 200
      data << 
        {:device => {
          :device_id => device.id,
          :name => device.name,
          :registration_id => device.registration_id
        }
      }
        data << {:status => sent_status}
      
    end 

    desc "Accept the device sharing invitation"
    params do
      requires :invitation_key, :desc => "Invitation key"
    end  
    post 'accept_sharing_invitation' do
      authenticated_user
      status 200
      forbidden_request! unless current_user.has_authorization_to?(:accept, DeviceInvitation)

      device_invitation = DeviceInvitation.where(invitation_key: params[:invitation_key]).first
      not_found!(DEVICE_INVITATION_NOT_FOUND, "Device invitation key: " + params[:invitation_key].to_s) unless device_invitation
      invalid_request!(IVITATION_NOT_FOR_CURRENT_USER,Settings.share_with_mail_not_same) unless current_user.email == device_invitation.shared_with

      device = Device.where(id: device_invitation.device_id).first
      shared_device = device.shared_devices.new
      shared_device.shared_by = device_invitation.shared_by
      shared_device.shared_with = current_user.id
      shared_device.save!
      device_invitation.destroy
      "Invitation accepted"
      
    end 

    desc "Evaluate if any pending device sharing invitations are present and send reminder emails to the target users"
    post 'send_sharing_invitation_reminder' do
      authenticated_user
      status 200
      forbidden_request! unless current_user.has_authorization_to?(:send, DeviceInvitation)

      device_invitations = DeviceInvitation.where("updated_at <= ?", Time.now-Settings.days_crossed.to_i.days )
      device_invitations.each do |device_invitation|
        Thread.new{
          DevicesAPI_v1.send_reminder(device_invitation)
       } 
      end  

      
      
    end 

    desc "Remove sharing invitations of  own device for specified users"
    params do 
      requires :emails,:type => String, :desc => "Comma seperated list of email ids"
    end 
    delete ':registration_id/remove_sharing_invitations' do
      authenticated_user
      status 200

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:share, device)

      emails = params[:emails].split(',')
      device_invitations = device.device_invitations.where(shared_with: emails,shared_by: current_user.id) 
      device_invitations.each do |device_invitation|
        device_invitation.destroy
      end
      "Done"
    end 

    desc "Remove sharing of own device for specified users"
    params do 
      requires :user_ids,:type => String, :desc => "Comma seperated list of user ids"
    end 
    delete ':registration_id/remove_sharing' do
      authenticated_user
      status 200

      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:share, device)

      user_ids = params[:user_ids].split(',')
      shared_devices = device.shared_devices.where(shared_with: user_ids,shared_by: current_user.id) 
      shared_devices.each do |shared_device|
        shared_device.destroy
      end  

      "Done"
    end  


    http_basic do |username, password|
      username == "device" && password == "device@123"
    end

  desc "Session summary"
  params do
    requires :mode, :type => String, :desc => "Mode (upnp OR stun OR relay) "
    optional :start_time 
    optional :end_time
    requires :session_time, :type => Integer
 end


  post ':registration_id/session_summary' do
    device = Device.where(registration_id: params[:registration_id]).first
    not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
    status 200
    case params[:mode]
      when "upnp","1"
        device.upnp_usage +=params[:session_time]
        device.upnp_count +=1
      when "stun","2"
        device.stun_usage +=params[:session_time]
        device.stun_count +=1
      when "relay","3"
        device.relay_usage +=params[:session_time] 
        device.relay_count +=1
        device.latest_relay_usage = params[:session_time] 
      else
        invalid_parameter!("mode")
    end
       device.last_accessed_date = Time.now 
       device.save! 
     
    end

    

  end

  def self.session_key(value)
    sha256 = Digest::SHA256.new
    sha256.update (value)
    session_key = sha256.hexdigest.upcase

  end

  def self.generate_channel_id(length)
    rand.to_s[2...length +2].to_i
  end

  def self.send_reminder(device_invitation)
    device_invitation.reminder_count +=1
    device_invitation.save!
    user = User.where(id: device_invitation.shared_by).first  
    Notifier.device_share_reminder(user.name,device_invitation.shared_with,device_invitation.invitation_key).deliver if user
  end  


end
