require 'json'
require 'grape'
require 'error_format_helpers'
require 'ip'
require 'timeout'
require 'thread'

# Class :- DevicesAPI_v1
# Description :- This file contains all device related API for version 'v1'
#
class DevicesAPI_v1 < Grape::API

  include Audited::Adapters::ActiveRecord
  formatter :json, SuccessFormatter
  format :json
  default_format :json
 
  # Version 'v1' :- Used for all below API
  version 'v1', :using => :path, :format => :json

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

    # Query :- Register a new Device
    # Method :- POST
    # Parameters :-
    #         name  :- Device Name
    #         registration_id :- Device Registration ID
    #         firmware_version :- Device Firmware version
    #         time_zone :- Device Time Zone
    #         mode :- Device Mode ( upnp,stun or relay )
    #         host_ssid :- Router SSID
    #         host_router :- Router Name
    #         local_ip :- Device Local IP
    # Response :-
    #         Return Device  Information with Auth-token

    desc "Create a device that belongs to current user. "

    params do

      requires :name, :type => String, :desc => "Name of the device"
      requires :registration_id, :type => String, :desc => "Registration Id of the device"
      requires :firmware_version, :type => String,  :desc => "Firmware version number in the format xx.yy or xx.yy.zz."
      requires :time_zone,:type => Float, :desc => "Time Zone in the format +12.00 or -3.30 ."
      optional :mode, :desc => "Device accessibility mode. (upnp OR stun OR relay OR presence_detection OR motion_detection)"
      optional :parent_id, :desc => "Id of the parent device"
      optional :host_ssid, :desc => "Router SSID where camera register"
      optional :host_router, :desc => "Host Router name"
      optional :local_ip, :validate_ip_address_format => true, :type => String, :desc => "Device Local IP"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

    end

    post 'register' do

      active_user = authenticated_user ;

      physical_device = true ;
      device_model = nil ;
      device_master = nil ;
      parent_device = nil;

      invalid_parameter!("registration_id") unless params[:registration_id].length == Settings.registration_id_length
      
      device_type_code   = params[:registration_id][0..1];
      device_model_no    = "";
      device_mac_address = params[:registration_id][6..17];
      device_message     = params[:registration_id][0..17];

      #first find that device is registered or not
      registered_device = Device.where(registration_id: params[:registration_id]).first

      device_type = DeviceType.where(type_code: device_type_code).first
      not_found!(TYPE_NOT_FOUND,"DeviceType: " + device_type_code.to_s) unless device_type
      
      begin
        device_master_batchid=DeviceMaster.find_by_registration_id(params[:registration_id]).device_master_batch_id
        device_model_no=DeviceMasterBatch.find(device_master_batchid).device_model_id
        device_model = DeviceModel.where(id: device_model_no).first
      rescue NoMethodError=> ne
        Rails.logger.error("Caught Exception #{ne.inspect}")
        not_found!(MODEL_NOT_FOUND, "DeviceModel: " + device_model_no.to_s) unless device_model
      end
      
      not_found!(TYPE_NOT_FOUND,"Invalid device type and device model combination" ) unless device_type.id == device_model.device_type_id

      #check for connect model
      is_connect_model=GeneralSettings.connect_settings[:model].include?(device_model.model_no) 
      # Device is not registered with Hubble Eco System
      unless registered_device

        # check that physical device present in Device Master
        device_master = DeviceMaster.where(registration_id: params[:registration_id], mac_address: device_mac_address).first

        unless device_master

          # it is possible that MAC address is present in Device Master with different registration ID
          invalid_device = DeviceMaster.where(mac_address: device_mac_address).first ;

          # check in device table if device mac address is present or NOT.
          unless invalid_device

            invalid_device = Device.select("id").where(mac_address: device_mac_address).first ;

          end
          # Invalid registration ID because same mac address has found with different registration ID
          bad_request!(INVALID_REGISTRATION_ID, "Invalid Registration_id, mac_address already exist") if invalid_device ;

        end

        if device_model.udid_scheme == "virtual"

            # considered as virtual device
            random_number = Base64.encode64(Digest::MD5.hexdigest(device_message))[0..7]
            invalid_parameter!("registration_id") if  ( random_number == nil  || random_number.upcase != params[:registration_id][18..25].upcase )

            physical_device = false ;
        else

            # considered as physical device

            # commented below line because device master query is executed on line 90
            # device_master = DeviceMaster.where(registration_id: params[:registration_id]).first

            unless device_master

              # TODO :- create function for "api_call_issue"
              api_call_issue = ApiCallIssues.where("api_type = ? AND error_reason = ? AND error_data = ?","device_register","registration_id_not_in_master",params[:registration_id]).first

              unless api_call_issue

                api_call_issue = ApiCallIssues.new
                api_call_issue.api_type = "device_register"
                api_call_issue.error_data = params[:registration_id]
                api_call_issue.error_reason = "registration_id_not_in_master"

              end

              api_call_issue.count +=1
              api_call_issue.save!
              not_found!(REGISTRATION_ID_NOT_FOUND, "Registration id : " + params[:registration_id].to_s + " in device master");

            end
        end  # if condition completed.

      end

      # If device is registered with system, so device master is NULL.
      unless device_master

        device_master = DeviceMaster.where(registration_id: params[:registration_id]).first
      end

      # checking that registered device is virtual device or not

      if registered_device

        # device master should not be nil if it is physical device
        physical_device = false unless device_master
      end

      
      # Checking that device is already registered with current user or not.
      existing_device = active_user.devices.where(registration_id: params[:registration_id]).first

      # check that device is deleted or not.

      recover_device = Device.only_deleted.where("registration_id = ?", params[:registration_id]).first unless existing_device

      if recover_device

        # Recover device if it was deleted previously.
        recover_device.recover ;
        # Delete pending critical command
        # it is required that server should not send "reset_factory" command if it is present in
        # critical command after registration process.
        recover_device.device_critical_commands.destroy_all;

        # All associations marked as :dependent => :destroy are also recursively recovered.
        # If you would like to disable this behavior, you can call recover with the recursive option:
        # Paranoiac.only_deleted.where("name = ?", "not dead yet").first.recover(:recursive => false)
        # TODO:- Remove destroy_all, it is time consuming process, please use delete_all if usable.
        recover_device.device_events.includes('').delete_all if recover_device.device_events;
        # Delete S3 Folder
        delete_folder();
        recover_device.user_id = active_user.id

      end

      # Assign existed or recoverd device to "device" object.
      device = recover_device || existing_device ;

      unless device

        # if device is registered with different account, then registered device is not NULL & "device" object is null
        # Note :- Customer can return device without removing device from account and other user is trying to register
        #         device again.
        # bad_request!(INVALID_REGISTRATION_ID, "Device is already registered with other account") if registered_device ;

        if registered_device

          device = registered_device ;
          # Delete all events which are associate with device
          device.device_events.includes('').delete_all  if device.device_events ;
          # destroy critical command
          device.device_critical_commands.destroy_all if device.device_critical_commands ;
          # Delete all Event Log
          EventLog.where(registration_id: params[:registration_id]).delete_all ;
          # Delete S3 Folder
          delete_folder();
          # Re-assign device to current user.
          device.user_id = active_user.id ;

          # Reset parent device 
          device.parent_id=params[:parent_id];

          # Remove the device account from External server
          external_notifier = ExternalNotifier.new({:device => device})
          external_notifier.device_delete({:device => device})

        else

          # create a new device in User account
          device = active_user.devices.new
          device.last_accessed_date = Time.now
          device.device_model_id = device_model.id

        end
        
      end

      unless is_connect_model
        device.plan_id = Settings.default_device_plan
      else
        device.device_model_id = device_model.id
        device.plan_id = GeneralSettings.connect_settings[:default_device_plan]
      end
      # Assing device information which are received from application.
      device.name = params[:name] if params[:name]

      device.registration_id = params[:registration_id].upcase if params[:registration_id]
      device.mac_address = device_mac_address.upcase

      device.time_zone = params[:time_zone] if params[:time_zone]

      device.firmware_version = params[:firmware_version].downcase if params[:firmware_version]

      # Assign Host Router information
      device.host_ssid = params[:host_ssid] if params[:host_ssid] ; 
      device.host_router = params[:host_router] if params[:host_router] ;

      if params[:parent_id]
      
        invalid_parameter!("registration_id") unless params[:parent_id].length == Settings.registration_id_length
   
        parent_device = active_user.devices.where(registration_id: params[:parent_id]).first
        not_found!(PARENT_DEVICE_NOT_FOUND, "Parent Device: " + params[:parent_id].to_s) unless parent_device
      
        device.parent_id =  parent_device.id
  
      end

      if existing_device || registered_device

        # Destroy old device location information
        if device.device_location
          device.device_location.destroy ;
        end
        
        # Create new entry for device location
        device.device_location = DeviceLocation.new
        device.device_location.local_ip = params[:local_ip] if params[:local_ip]
        ip_address = get_ip_address();
        device.device_location.remote_ip = ip_address ;
        iso_code = get_country_ISOCode(ip_address);
        device.device_location.remote_iso_code = iso_code;
        device.device_location.remote_region_code = get_LoadBalancer_regionCode(iso_code);

      else
        
        # create device location table
        device.device_location = DeviceLocation.new
        device.device_location.local_ip = params[:local_ip] if params[:local_ip]
        ip_address = get_ip_address();
        device.device_location.remote_ip = ip_address;
        iso_code = get_country_ISOCode(ip_address);
        device.device_location.remote_iso_code = iso_code;
        device.device_location.remote_region_code = get_LoadBalancer_regionCode(iso_code);
        # create device capability table in database
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

        # Below code is used for backward compability
        unless supportnewVersion!(device.registration_id[2..5],device.firmware_version)
          # Device is not able support new version of server.
          device.mode = params[:mode].downcase if params[:mode]
        end

      end

  
      # device is already registered with current user. so it is required that
      # we should not change authentication token & derived key
      unless existing_device
        device.plan_id = Settings.default_device_plan
        # We check if the device already has an active free trial and assign the plan if the trial is still active
        device_free_trial = DeviceFreeTrial.where(device_registration_id: device.registration_id, status: FREE_TRIAL_STATUS_ACTIVE, user_id: active_user.id).first
        if (device_free_trial.present?)
          device.plan_id = device_free_trial.plan_id
        end
        device.auth_token = device.generate_token ;
        device.derived_key = device.generate_derived_key(device.auth_token) ;
      end
      device.tenant_id = params[:tenant_id] if params[:tenant_id].present?
      device.registration_at = Time.now.utc;

      Audit.as_user(active_user) do
        device.save!
        device.device_location.save! ;
      end

      # Signature will be passed in to the JavaScript code which calls Recurly.js to build the form.

      # TODO: Check if we need this property to preserve backward compatibility
      device.signature = nil  
      
      create_aws_folders(device);

      if params[:parent_id]

        tag_type = device.mode == "presence_detection" ? 1 : 2
        
        formatted_mac="%s:%s:%s:%s:%s:%s"

        formatted_mac= formatted_mac % [device_mac_address[0..-11],
          device_mac_address[2..-9],
          device_mac_address[4..-7],
          device_mac_address[6..-5],
          device_mac_address[8..-3],
          device_mac_address[10..-1]]

        command = Settings.camera_commands.add_ble_tag % [params[:registration_id],formatted_mac, tag_type ]

        response = send_command_over_stun(parent_device,command);

        internal_error_with_data!(ERROR_SENDING_COMMAND, ERRORS[response[:device_response][:device_response_code]], response) unless response[:device_response][:device_response_code] == 200 ;

      end



      $gabba.event(Settings.catergory_devices, "Register", device.registration_id);

      

      # Send response message to application
      status 200
      { 
        "id" => device.id,
        "registration_id" => device.registration_id,
        "auth_token" => device.auth_token,
        "signature" => device.signature,
        "plan_id" => device.plan_id
      }
    end
    # Complete Query:- Device Registration

     # Query :- Verify devices.
    # Method :- GET
    # Parameters :- registration_ids
    # Response :-Return devices info
    
    desc "Verify Devices "

      params do
        requires :registration_ids, :type => String, :desc => "Comma separated list of registration ids"
      end

      get 'verify_devices' do

        active_user = authenticated_user ;
        
        status 200
       
      device_items = [] ;
          
      registration_ids = params[:registration_ids].split(',') if params[:registration_ids]

      device_item=nil

      registration_ids.each {|reg_id|

        device_item=VerifyDeviceItem.new
        device_item.registration_id = reg_id
        
        if reg_id.length != Settings.registration_id_length
          device_item.is_valid=false
          device_item.messages.push("Invalid parameter: parent_id")            
        else 
          device_mac_address = reg_id[6..17];
          device_master = DeviceMaster.select("registration_id").where(registration_id: reg_id, mac_address: device_mac_address).first
          if device_master.nil?
            device_item.is_valid=false
            device_item.messages.push("Device not found")
          else
            device_item.is_valid=true
          end
         
        end

       device_items <<  device_item
      }
      present device_items, with: VerifyDeviceItem::Entity

    end 

    #Device registration Complete

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
      
        present list, with: Device::Entity, type: :full
    end
    #Complete Query :- List of all devices that belong to current User.

    # Query :- Get the list of all the devices shared by current user with other users
    # Method :- GET
    # Parameters :-
    #         user_id  :- User ID whom you want to share device
    # Response :-
    #         Return  invitations informaton.
    desc "Get the list of all the devices shared by current user with other users"

      params do
        optional :user_id,:type => Integer, :desc => "User id to be specified by admin ."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      get 'sharing_invitations_by_me' do

        active_user =  authenticated_user ;
        device_invitations = nil ;
        status 200

        if params[:user_id]

          user = User.select("id").where(id: params[:user_id]).first
          not_found!(USER_NOT_FOUND, "User: " + params[:user_id].to_s) unless user
          forbidden_request! unless active_user.has_authorization_to?(:read_any, DeviceInvitation)
          device_invitations = DeviceInvitation.where(shared_by: params[:user_id]) 

        else

          device_invitations = DeviceInvitation.where(shared_by: active_user.id)

        end
        present device_invitations, with: DeviceInvitation::Entity 
      end
    # Complete Query :- "sharing_invitations_by_me"

    # Query :- Get the list of all the devices shared by current user with other users
    # Method :- GET
    # Parameters :-
    #         user_id  :- User ID ( admin access required)
    # Response :-
    #         Return  invitations informaton.
    desc "Get the list of all the devices shared by current user with other users" 

      params do
        optional :user_id,:type => Integer, :desc => "User id to be specified by admin ."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      get 'shared_by_me' do

        active_user = authenticated_user ;
        status 200

        if params[:user_id]
          user = User.select("id").where(id: params[:user_id]).first
          not_found!(USER_NOT_FOUND, "User: " + params[:user_id].to_s) unless user
          forbidden_request! unless active_user.has_authorization_to?(:read_any, DeviceInvitation)
          device_invitations = SharedDevice.where(shared_by: params[:user_id])

        else
          device_invitations = SharedDevice.where(shared_by: active_user.id)

        end

        present device_invitations, with: SharedDevice::Entity

      end
    # Complete query :- "shared_by_me"

    # Query :- Get the list of all the devices shared by other users with current user
    # Method :- GET
    # Parameters :-
    #         user_id  :- User ID ( admin access required)
    # Response :-
    #         Return  shared device informaton.
    desc "Get the list of all the devices shared by other users with current user" 

      params do
        optional :user_id,:type => Integer, :desc => "User id to be specified by admin ."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      get 'shared_with_me' do

        active_user = authenticated_user ;
        status 200

        if params[:user_id]
          user = User.select("id").where(id: params[:user_id]).first
          not_found!(USER_NOT_FOUND, "User: " + params[:user_id].to_s) unless user
          forbidden_request! unless active_user.has_authorization_to?(:read_any, DeviceInvitation)

          shared_devices = SharedDevice.where(shared_with: params[:user_id]);

        else
          shared_devices = SharedDevice.where(shared_with: active_user.id);

        end

        present shared_devices, with: SharedDevice::Entity
      end
    # Complete query :- shared_with_me

    desc "Subscription information of all the user's devices"
    get 'subscriptions' do
      Device.get_subscriptions(authenticated_user)
    end

    desc "Apply subscription (plan) to devices", {
    :notes => <<-NOTE
      You can only apply a subscription plan for which the user has already subscribed.
      When a plan_id is not specified, the default system plan would be applied to the devices. 
      NOTE
    }
    params do
      optional :plan_id, :type => String, :desc => "The plan that needs to be applied for the devices"
      requires :devices_registration_id, :type => Array, :desc => "The list of registration_id of the devices that need to be updated"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    put 'subscriptions' do
      active_user = authenticated_user
      bad_request!(400, "Atleast one device registration_id must be present!") unless params[:devices_registration_id].length > 0              
      if (params[:plan_id].present?)
        subscription_plan = SubscriptionPlan.where(plan_id: params[:plan_id]).first()
        not_found!(PLAN_NOT_FOUND, "Plan: " + params[:plan_id].to_s) unless subscription_plan.tenant_id==params[:tenant_id] if params[:tenant_id].present?
        not_found!(PLAN_NOT_FOUND, "Plan: " + params[:plan_id].to_s) unless subscription_plan
        Device.apply_subscriptions(active_user, params[:plan_id], params[:devices_registration_id])
      else
        Device.change_subscriptions(Settings.default_device_plan, params[:devices_registration_id], active_user.id)
      end
    end

    # Query :- Get Device Registration Detail
    # Method :- GET
    # Parameters :-
    #         device_address :- Last 6 digit MAC address
    # Response :-
    #         Return device status
    #
    desc "Get Device Registration Detail"

      params do

        requires :device_address, :type => String, :length => HubbleConfiguration::REGISTRATION_DETAIL_ID_LENGTH, :desc => "Device Mac address"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

      end

      get 'registration_detail' do

        active_user = authenticated_user ;

        # Access denied if user does not have permission.
        access_denied! unless active_user ;

        remote_ip_address = get_ip_address;

        mac_address_content = params[:device_address] ;

        registration_details = RegistrationDetail.where("remote_ip = ? AND mac_address like ?",remote_ip_address,"%#{mac_address_content}").first;
        not_found!(REGISTRATION_DETAIL_NOT_FOUND,mac_address_content.to_s) unless registration_details ;

        if ( !registration_details.validate_registration_detail_expire_time)

          bad_request!(REGISTRATION_DETAIL_EXPIRES,HubbleErrorMessage::REGISTERATION_DETAIL_EXPIRES) ;

        else

          registration_details.device_status = get_device_status(registration_details.registration_id,active_user) ;

          status 200 ;
          present registration_details, with: RegistrationDetail::Entity, type: :full

        end
    
      end

    # complete query : "registration_details"
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

    # Query :- Get the list of events
    # Method :- GET
    # Parameters :-
    #        before_start_time :- Before this time
    #        event_code :- Event code when event is generated
    #        alerts :- List of alerts
    #        page :- Page Number
    #        size :- Size of page
    # Response :-
    #         Return  List of events
    
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
        optional :include_child_events, :type => Boolean, :desc => "Allowed values are true or false"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

      end

      get ':registration_id/events' do

        active_user = authenticated_user ;

        params[:include_child_events]= params[:include_child_events] == nil ? true : params[:include_child_events]

        status 200

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:list, device)

        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"

        params[:size] = Settings.default_page_size unless params[:size] ;
        events = [] ;
        device_events = [] ;
        alerts = params[:alerts].split(',') if params[:alerts]
        
        if params[:event_code]
          device_events = DeviceEvent.where("event_code like ?","#{params[:event_code]}%").paginate(:page => params[:page], :per_page => params[:size])
        elsif (params[:before_start_time] && params[:alerts])
          device_events = DeviceEvent.where("time_stamp <= ? AND alert in (?) AND device_id = ?",params[:before_start_time],alerts,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
        elsif params[:before_start_time]
          device_events = DeviceEvent.where("time_stamp <= ? AND device_id = ?",params[:before_start_time],device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size]) 
        elsif params[:alerts] 
          device_events = DeviceEvent.where("alert in (?) AND device_id = ?",alerts,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size]) 
        elsif params[:include_child_events]  
           device_events = DeviceEvent.where("parent_id = ? OR device_id = ?",device.id,device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
        else 
          device_events = DeviceEvent.where(device_id: device.id).order('time_stamp DESC').paginate(:page => params[:page], :per_page => params[:size])
        end

        event_threads = [] ;
        semaphore = Mutex.new ;

        device_events.each do |event|

          event_threads << Thread.new {

            begin
              
             if event.storage_mode.nil? or event.storage_mode == 0
               data = get_playlist_data(device, event.event_code, true) if (event.alert == EventType::MOTION_DETECT_EVENT && event.event_code)
             else
               data = DevicesAPI_v1.new.get_sdcard_data(event);
             end

              alert_name = get_alert_name(event.alert)
              semaphore.synchronize {
                events << {
                  :id => event.id[0],
                  :alert => event.alert,
                  :value => event.value,
                  :alert_name => alert_name,
                  :time_stamp => event.event_time,
                  :storage_mode => event.storage_mode,
                  :data => data
                }
              }

              rescue Exception => exception
              ensure
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;
            end

          }

        event_threads.each { |thr| thr.join } 
        sorted_events = events.sort_by { |k| k[:time_stamp] }

        {
          :total_events => device_events.count,
          :total_pages => device_events.total_pages,
          :events => sorted_events.reverse
        }
      end
      
        
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
      event_threads = []
      events = []
      semaphore = Mutex.new

      device_events.each do |event|

        event_threads << Thread.new {

          begin
            
            data = get_playlist_data(event.device, event.event_code, true) if (event.alert == EventType::MOTION_DETECT_EVENT && event.event_code)
            alert_name = get_alert_name(event.alert)
            semaphore.synchronize {
              events << {
                :id => event.id[0],
                :alert => event.alert,
                :value => event.value,
                :alert_name => alert_name,
                :time_stamp => event.event_time,
                :data => data,
                :device_registration_id => event.device.registration_id
              }
            }

            rescue Exception => exception
            ensure
              ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
              ActiveRecord::Base.clear_active_connections!
          end
        }
      end

      event_threads.each { |thr| thr.join }
      sorted_events = events.sort_by { |k| k[:time_stamp] }

      {
        :total_events => device_events.count,
        :total_pages => device_events.total_pages,
        :events => sorted_events.reverse
      }
    end    
    # Complete Query :- "events"

    # Query :- Delete device events
    # Method :- DELETE
    # Parameters :-
    #        event_ids :- Event id when event is generated
    # Response :-
    #         Return  Status

    desc "Delete device events."
      params do
        optional :event_ids,:type => String, :desc => "Comma separated list of event ids." 
      end

      delete ':registration_id/events' do

        active_user = authenticated_user ;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:delete_event, device)

        if params[:event_ids]

          event_ids_array = params[:event_ids].split(',') ;
          device_events =  device.device_events.where(id: event_ids_array) ;

          device_events.each do |event|
            delete_events(params[:registration_id],event.event_code) if event.event_code
            event.destroy
          end

        else

          device.device_events.includes('').delete_all  if device.device_events ;
          delete_all_s3_events(params[:registration_id]);

        end

        "Events deleted!"
      end
    # Complete Query :- "events"

    # Query :- Get basic information of a device that belongs to current user. 
    # Method :- GET
    # Parameters :-
    #        registration_id :- Device Registration ID
    # Response :-
    #         Return  Device information
    desc "Get basic information of a device that belongs to current user. "
    
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      get ':registration_id' do

        active_user = authenticated_user ;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:list, device) ;

        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"

        # Provide device image information
        deviceSnapStatus = device_logo_is_exist!(device.registration_id);

        if deviceSnapStatus[:status]

            device.snaps_url = deviceSnapStatus[:logo_url];
            device.snaps_modified_at = deviceSnapStatus[:snap_modified_time];

        else

            s3 = AWS::S3.new
            bucketObject = s3.buckets[Settings.s3_bucket_name].objects['hubble.png'] ;
            device.snaps_url = bucketObject.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s ;
            device.snaps_modified_at = nil;

        end
        device.is_available = is_device_available(device)[:is_available] ;
        present device, with: Device::Entity, type: :full
      end
    # Complete Query:- "get basic information of a device belongs to current user"

    desc "Get free trial information of a device"
     params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end
    get ':registration_id/free_trial' do
      active_user = authenticated_user ;
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless active_user.has_authorization_to?(:list, device) ;
      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      device_free_trial = DeviceFreeTrial.where(device_registration_id: device.registration_id, user_id: active_user.id).first
      present device_free_trial, with: DeviceFreeTrial::Entity, type: :complete
    end

    desc "Enable free trial for a device"
     params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end
    post ':registration_id/free_trial' do
      active_user = authenticated_user ;
      device = Device.where(registration_id: params[:registration_id], user_id: active_user.id).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless active_user.has_authorization_to?(:list, device) ;
      invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
      device_free_trial = DeviceFreeTrial.where(device_registration_id: device.registration_id, user_id: active_user.id).first
      if (device_free_trial.present?) 
        # Check if the user already has an active free trial and apply it to their device (in case of re-registration etc)
        if (device_free_trial.status == FREE_TRIAL_STATUS_ACTIVE)
          device.apply_free_trial(Settings.free_trial_plan)
        else
          invalid_request!(DEVICE_FREE_TRIAL_CLAIMED, ERRORS[DEVICE_FREE_TRIAL_CLAIMED])
        end
      else
        tot_free_trial = DeviceFreeTrial.where(device_registration_id: device.registration_id)
        # Check if device has crossed its life time availability (2) of free trials
        if (tot_free_trial.present? && tot_free_trial.length > 1)
          invalid_request!(DEVICE_FREE_TRIAL_CLAIMED, ERRORS[DEVICE_FREE_TRIAL_CLAIMED])
        end
        device_free_trial = device.create_free_trial()
      end
      present device_free_trial, with: DeviceFreeTrial::Entity, type: :complete
    end

    # Query :- Send a control command to the device that belongs to current user.  
    # Method :- POST
    # Parameters :-
    #        command :- Command which application want to send to device
    # Response :-
    #         Return  status message

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
        requires :command,:type => String, :desc => "Command that should be sent to the device."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':registration_id/send_command' do
        
        active_user = authenticated_user ;
      
        device = active_user.devices.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        #forbidden_request! unless active_user.can_access_device?(:send_command, device,active_user)

        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
        status 200
        send_command_over_stun(device, params[:command])
      end
    # Complete Query :- "send_command"

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

        device = active_user.devices.where(registration_id: params[:registration_id]).includes(:device_location).first ;

        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        #forbidden_request! unless active_user.can_access_device?(:create_session, device,active_user ) ;

        bad_request!(MAC_ADDRESS_NULL,"Mac address is null") unless device.mac_address ;
        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive" ;

        device.save!

        device_model = DeviceModel.where(id: device.device_model_id).first
        relay_rtmp_ip = get_wowza_rtmp_address(device.device_location.remote_region_code,device_model.model_no) 


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

          status 200
          {
            :url => parsed_device_response["session_key"],
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

                status 200
                $gabba.event(Settings.catergory_devices, "Session","Relay RTMP") 
                {
                  :url => session_key,
                  :mode => mode
                }

            else
              internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Invalid response received from device.", response)

            end
        end # end of supportNewversion condition.

   end
   # Complete Query :- Create a Sessiom for Devcie which belongs to Current user

    # Query :- Close session for a device
    # Method :- POST
    # Parameters :-
    #         session_id   :- Session ID
    # Response :-
    #         Return nothing.

    desc "Close session for a device"

      params do
        requires :session_id, :type => String, :desc => "Session stream id. "
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post 'close_session' do

        active_user = authenticated_user ;

        status 200

        device = Device.where(stream_name: params[:session_id]).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:session_id].to_s) unless device ;
        forbidden_request! unless active_user.has_authorization_to?(:close_session, Device) ;

        command = Settings.camera_commands.close_session_command
        stunResponse = send_command_over_stun(device, command) ;

        # After receving "close_session" request, it is required that server should clear stream name 
        # from active record
        device.clear_stream_name();

        Thread.new {

          begin
            event_log = active_user.event_logs.new ;
            event_log.event_name = EventLogMessage::CLOSE_SESSION ;
            event_log.event_description = EventLogMessage::CLOSE_BY_DEVICE ;
            event_log.remote_ip = get_ip_address ;
            event_log.time_stamp = Time.now.utc ;
            event_log.registration_id = device.registration_id ;
            event_log.user_agent = get_user_agent ;
            event_log.save!

            rescue Exception => exception
            ensure
              ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
              ActiveRecord::Base.clear_active_connections! ;
          end
        }

        # Note:- 
        # NAT port is closed by router immediately after device has sent "keep-alive" packet to server.
        # In this meantime, API server is trying to send "Stun request" on NAT port which is closed by router.
        # It may be reason that stun request does not reach device.
        if ( stunResponse[:device_response][:device_response_code] != 200)
          # start thread to send close_session command
          Thread.new {

            begin
              closeSessionRetryCounter = HubbleConfiguration::CLOSE_SESSION_RETRY ; 
              iCounter = 0;

              begin

                # Increase counter value
                iCounter = iCounter + 1 ;
                # send "close_session" command to device
                stunResponse = send_command_over_stun(device, command) ;

              end while ( (stunResponse[:device_response][:device_response_code] != 200) &&  (iCounter < closeSessionRetryCounter) )

              # When it is failed then only store information
              if ( iCounter >= closeSessionRetryCounter && stunResponse[:device_response][:device_response_code] != 200)

                # Send notification mail to server team
                send_hubble_device_issue_mail(
                                            device,
                                            HubbleIssueNotification::DEVICE_CLOSE_SESSION_ID,
                                            HubbleIssueNotification::DEVICE_CLOSE_SESSION_TYPE,
                                            HubbleIssueNotification::DEVICE_CLOSE_SESSION_REASON,
                                            stunResponse[:device_response][:device_response_code],
                                            env["HTTP_HOST"]
                                            )

                api_call_issue = ApiCallIssues.where("api_type = ? AND error_reason = ? AND error_data = ?",
                                                    HubbleIssueNotification::DEVICE_CLOSE_SESSION_TYPE,
                                                    HubbleIssueNotification::DEVICE_CLOSE_SESSION_REASON,
                                                    device.registration_id.to_s).first

                unless api_call_issue

                  api_call_issue = ApiCallIssues.new
                  api_call_issue.api_type = HubbleIssueNotification::DEVICE_CLOSE_SESSION_TYPE ;
                  api_call_issue.error_data = device.registration_id.to_s
                  api_call_issue.error_reason = HubbleIssueNotification::DEVICE_CLOSE_SESSION_REASON ;

                end

                api_call_issue.count +=1
                api_call_issue.save!

              end

              rescue Exception => exception
              ensure
                # Active record connections open when Thread is created
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;
            end

          }
          # End of Thread

        end
        # return stun response to application
        stunResponse ;
      end
    # Complete Query :- "close_session"

    # Query :- Authenticate stream name
    # Method :- POST
    # Parameters :-
    #         session_id   :- Session ID
    # Response :-
    #         Return status.

    desc "Authenticate Stream name"

      params do
        requires :session_id, :type => String, :desc => "Session stream id. "
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post 'authenticate_stream' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:validate_stream, Device) ;

        stream_status = false;
        device = Device.where(stream_name: params[:session_id]).first ;

        stream_status = device ? true : false ;

        status 200
        {
          :stream_status => stream_status
        }

      end
    # Complete Query :- "authenticate_stream"

    # Query :- Stream Stats Info
    # Method :- POST
    # Parameters :-
    #         relay_rtmp_ip   :- Relay RTMP IP Address
    #         application_name :- Application Name
    #         stream :- Stream Name
    # Response :-
    #         Return status.

    desc "Stream stats Info"

      params do
        requires :relay_rtmp_ip, :validate_ip_address_format => true, :desc => "Relay RTMP IP Address"
        optional :application,   :type => String, :desc => "Application Name (Default 'camera')"
        requires :stream,        :type => String, :desc => "Stream Name"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post 'stream_info' do

        active_user = authenticated_user ;

        stream_stat_info = nil ;

        unless params[:application]
          params[:application] = 'camera' ;
        end

        stream_stat_info = get_wowza_stream_stat(params[:relay_rtmp_ip],params[:application],params[:stream]);

        status 200
        stream_stat_info ;

      end
    # Complete Query :- "authenticate_stream"

    # Query :- Send close session information to server"
    # Method :- POST
    # Parameters :-
    #      registration_id :- Device Registration ID
    # Response :-
    #         Return status informaton to application.

    desc "Send close session information"

      params do
        optional :mode, :desc => "Session Mode"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':registration_id/app_session_summary' do

        active_user = authenticated_user ;

        event_log = active_user.event_logs.new ;
        event_log.event_name = EventLogMessage::CLOSE_SESSION ;
        event_log.event_description = params[:mode] if params[:mode] ;
        event_log.remote_ip = get_ip_address ;
        event_log.time_stamp = Time.now.utc ;
        event_log.registration_id = params[:registration_id] ;
        event_log.user_agent = get_user_agent ;
        event_log.save!

        status 200
        "Done"
      end
    # Complete Query :- "app_session_summary"

    # Query :- Delete a device that belongs to current user. 
    # Method :- DELETE
    # Parameters :-
    #         comment   :- Comment message for deleting device
    # Response :-
    #         Return session informaton to application.
    desc "Delete a device that belongs to current user. "

      params do
        optional :comment, :type => String, :desc => "Comment"
      end 

      delete ':registration_id' do

        active_user = authenticated_user ;
   
        device = Device.where(registration_id: params[:registration_id]).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        forbidden_request! unless active_user.has_authorization_to?(:destroy, device) ;

        device.audit_comment = params[:comment] if params[:comment] ;

        # delete device all device event
        device.device_events.includes('').delete_all  if device.device_events ;

        Audit.as_user(active_user) do
          device.destroy
        end  

        s3 = AWS::S3.new 

        bucket = AWS::S3.new.buckets[Settings.s3_bucket_name]  
        bucket.objects.with_prefix(Settings.s3_device_folder % [params[:registration_id]]).delete_all

        # Required to delete all Event Log which are present EventLog Database
        EventLog.where(registration_id: params[:registration_id]).delete_all ;

        $gabba.event(Settings.catergory_devices, "delete",params[:registration_id])  

        status 200

        Thread.new {

          ThreadUtility.with_connection do
            
            # send stun command 
            send_command_over_stun(device, Settings.camera_commands.reset_delete_command) ;

            # Send change password notification to User
            send_notification(active_user,device,EventType::DEVICE_REMOVED_EVENT.to_s,get_user_agent);

          end

        }
       
        if device.parent_id !=nil
          
          parent_device = Device.where(id: device.parent_id).first ;

          command = Settings.camera_commands.remove_ble_tag % [params[:registration_id]]
          response = send_command_over_stun(parent_device,command);
          internal_error_with_data!(ERROR_SENDING_COMMAND, ERRORS[response[:device_response][:device_response_code]], response) unless response[:device_response][:device_response_code] == 200 ;
        
        end

      #any other alidation like more than 2 censor can be added to camera?

        "Device deleted!"
      end
    # Complete Query :- "delete a device"

    # Query :- Update a bsic information of a device that belongs to current User
    # Method :- PUT
    # Parameters :-
    #         name  :- Device name
    #         time_zone :- Time Zone in the format
    #         firmware_version :- Device Firmware version
    #         mode  :- Device mode ( upnp,stun or relay)
    # Response :-
    #         Return User information
    desc "Update basic information of a device that belongs to current user. "

      params do

        optional :name, :type => String, :desc => "Device name"
        optional :time_zone,:type => Float, :desc => "Time Zone in the format +12.00 or -3.30 ."
        optional :firmware_version,:type => String, :desc => "Firmware version number."
        optional :mode,:desc => "Either of 'upnp', 'stun', or 'relay'"
        optional :host_ssid, :desc => "Router SSID where camera is registered"
        optional :host_router, :desc => "Router info where camera is registered"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

      end

      route [:put, :post], ':registration_id/basic' do

        active_user = authenticated_user ;

        device = Device.where(registration_id: params[:registration_id]).includes(:device_settings,:device_location).first ;
        not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device ;

        forbidden_request! unless active_user.has_authorization_to?(:update, device) ;
        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive" ;

        device.name = params[:name] if params[:name]
        device.time_zone = params[:time_zone] if params[:time_zone]
        device.firmware_version = params[:firmware_version] if (params[:firmware_version] && !params[:firmware_version].empty?)
        device.host_ssid = params[:host_ssid] if params[:host_ssid] ;
        device.host_router = params[:host_router] if params[:host_router] ;

        # device does not support new API server.
        unless supportnewVersion!(device.registration_id[2..5],device.firmware_version)
          device.mode = params[:mode] if params[:mode]
        end

        status 200
        Audit.as_user(active_user) do
          device.save!
        end
    
        present device, with: Device::Entity, type: :full
      end
    # Complete Query :- Update basic information of a device 

    # Query :- Update settings information of a device that belongs to current user.
    # Method :- PUT
    # Parameters :-
    #         settings  :- Device settings
    # Response :-
    #         Return User information
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
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
  
    put ':registration_id/settings' do

      active_user = authenticated_user ;

      device = active_user.devices.where(registration_id: params[:registration_id]).first ;
      not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device ;

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
        setting.value = value ;

        Audit.as_user(active_user) do  
          setting.save!
        end  

      end
      status 200
      present device.device_settings
    end
  # Complete Query :- Update settings information of a device that belongs to current user.

    # Query :- Check if a device (that belongs to current user) is available.
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return Device Status
    desc "Check if a device (that belongs to current user) is available."     
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      post ':registration_id/is_available' do

        active_user = authenticated_user ;
        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.can_access_device?(:send_command, device,active_user)

        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
        is_device_available(device)
      end
    # Complete Query :- "is_available"


    # Query :- Get Associate derived key of device
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return device derived key based on master key
    desc "Provide key which is associate with device auth token"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      post ':registration_id/secure_key' do

        active_user = authenticated_user ;

        device = active_user.devices.where(registration_id: params[:registration_id]).first ;
        not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device ;
        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive" ;

        unless device.derived_key

          device.derived_key = device.generate_derived_key(device.auth_token) ;
          device.save! ;

        end

        status 200
        {
          :secure_key => device.derived_key
        }

      end
    # Complete Query :- "derived_key"

=begin
    # Query :- Request recovery for a device that belongs to current user.

    desc "Request recovery for a device that belongs to current user. "

      params do
        requires :recovery_type, :validate_device_recovery_type => true, :desc => "Device recovery type. Currently supports 'upnp'."
        requires :status, :type => String, :desc => "Device recovery status.(recoverable or unrecoverable)"
      end

      post ':registration_id/request_recovery' do

        active_user = authenticated_user ;
        device = current_user.devices.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device

        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
        device.create_recovery(params[:recovery_type], get_ip_address, params[:status])
        #todo : do we need to check if recovery type matches the camera mode
        status 200
        "Done"
      end
    # Complete Query :- Request a recovery for a device
=end

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
        optional :model_no,valid_model_no: true,:desc => "List all devices based on model no"
        optional :q, :type => Hash, :desc => "Search parameter"
        optional :page, :type => Integer
        optional :size, :type => Integer
      end

      get do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, Device) ;
         devices=nil
        unless params[:model_no].present?
          search_result = Device.search(params[:q]) ;
          devices = params[:q] ? Device.search(params[:q]).result(distinct: true) : Device.includes(:device_location, :device_settings) ;
        else
          #q parameter not added
          model_no_record = DeviceModel.find_all_by_model_no(params[:model_no]).first
          devices=model_no_record.devices
        end
         present devices.paginate(:page => params[:page], :per_page => params[:size]) , with: Device::Entity, type: :full
      
        

      end
    # Complete Query :- "Get a list of devices"

    # Query :- Get list of logs. (Admin access needed)
    # Method :- GET
    # Parameters :-
    #         None
    # Response :-
    #         Return a Login information
    desc "Get list of logs. (Admin access needed)"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      get ':registration_id/logs'  do

        active_user = authenticated_user;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
  
        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive"
        forbidden_request! unless active_user.has_authorization_to?(:get_logs, Device);

        get_logs(device)
      end
    # Complete Query :- "Get a device logs"

    # Query :- Check if device exist or not
    # Method :- GET
    # Parameters :-
    #       None
    # Response :-
    #         Return device status 
    desc "Check if device exist or not"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      get ':registration_id/check_exist' do

        device = Device.where(registration_id: params[:registration_id]).first ;
        status 200
        device ? true : false

      end
    # Complete Query :- "check_exist"

    # Query :- Get Device Status
    # Method :- GET
    # Parameters :-
    #         registration_id :- Device Registration ID
    # Response :-
    #         Return device status
    #
    desc "Get a device status"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      get ':registration_id/check_status' do

        active_user = authenticated_user

        # Access denied if user does not have permission.
        access_denied! unless active_user

        # Set default device_status as '0' :- Device is not present in Device Master
        device_status  = DeviceStatus::NOT_FOUND_IN_DEVICE_MASTER ;

        # Get Device Addres from device registration ID
        device_mac_address = params[:registration_id][6..17] ;

        # First check that device is already present in Device Master or not.
        device_master = DeviceMaster.select("id,registration_id").where(registration_id: params[:registration_id], mac_address: device_mac_address).first

        if device_master

          # Device is present in device master.
          device = Device.with_deleted.where(registration_id: params[:registration_id]).first

          if device

            # Check that device is registered with current user or not.
            # Device is not deleted from current user account
            if  ( device.user_id  == active_user.id && device.deleted_at == nil)

              # Device is registered with current User.
              device_status = DeviceStatus::REGISTERED_CURRENT_USER;

            elsif  ( device.user_id  != active_user.id && device.deleted_at == nil)

              # Device is registered with other account & device is not deleted from that account.
              # Application can not register this device.
              # device_status = DeviceStatus::REGISTERED_OTHER_USER ;
              # allow to register device which is registered with other account
              device_status = DeviceStatus::DELETED_DEVICE;
            elsif ( device.deleted_at  != nil)

              # Device is deleted previously, so it is ready for registration.
              device_status = DeviceStatus::DELETED_DEVICE ;
            else

              # Unknown device status
              device_status = DeviceStatus::UNKNOWN_STATUS;
            end

          else

            # Device is not registered yet any time.
            device_status = DeviceStatus::NOT_REGISTERED_DEVICE ;

          end

        else

          # Device is not present in device master.
          device_status = DeviceStatus::NOT_FOUND_IN_DEVICE_MASTER;

        end
        # Return Reposonce with device Status
        status 200
        {
          :device_status => device_status,
          :registration_id => params[:registration_id]
        }

      end
    # Complete Query :- Get Device Status


=begin
    # Query :- "reboot complete"
    desc "Reboot complete "

      post ':registration_id/reboot_complete' do

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + params[:registration_id].to_s) unless device
      
        status 200
        "taking necessary action"
      end
    # Complete Query:- "reboot_complete"
=end

    # Query :- Get audits related to a specific device 
    # Method :- GET
    # Parameters :-
    #         registration_id :- Device Registration ID
    # Response :-
    #         Return device audit log
    #
    desc "Get audits related to a specific device "
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      get ':registration_id/audit'  do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, Device) ;

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;

        status 200
        device.audits
      end
    # Complete query :- "audits"


    # Query :- Send custom notification to one or more users.
    # Method :- POST
    # Parameters :-
    #         registration_id :- Device Registration ID
    #         message :- Notification message
    # Response :-
    #         Return status
    #
    desc "send custom notification to one or more users. "

      params do
        requires :registration_ids,:desc => "Comma seperated registration ids"
        requires :message, :type => String, :desc => "Notification message"
      end

      post 'notify_owners'  do

        active_user  =  authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, User) ;
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
    # Complete Query :- send custom notification to users

    # Query :- Get the device capability information.
    # Method :- GET
    # Parameters :-
    #         parameter :- Capabilitites parameter
    # Response :-
    #         Return device subscription info
    #   
    desc "Get the device capability information. "

      params do
      
        optional :parameter, :type => String, :desc => "Capabilitites Parameters, seperated by coma"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      get ':registration_id/capability' do

        active_user = authenticated_user ;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:list, device)

        device_model = DeviceModel.where(id: device.device_model_id).first
        not_found!(MODEL_NOT_FOUND, "DeviceModel: " + device.device_model_id.to_s) unless device_model

        # get device firmware version from device
        device_firmware_version = device.firmware_version ;

        # set model capability firmware version as device firmware version
        model_capability_firmware_version = device_firmware_version;

        # get all device model firmware version from capabilities 
        device_model_firmware_prefixes_array = device_model.device_model_capabilities.order('firmware_prefix desc').pluck(:firmware_prefix) ;

        # selected device_model_firmware_prefixes_at as 0
        device_model_firmware_prefixes_at = 0 ;

        device_model_firmware_prefixes_array.each { | device_model_firmware_version |

          if (Gem::Version.new(device_model_firmware_version) <= Gem::Version.new(device_firmware_version) )
              
            model_capability_firmware_version = device_model_firmware_version ;
            break ;

          end

          device_model_firmware_prefixes_at =  device_model_firmware_prefixes_at + 1 ;

        } ;

        if ( device_model_firmware_prefixes_at == device_model_firmware_prefixes_array.length )

          model_capability_firmware_version = device_model_firmware_prefixes_array.at(device_model_firmware_prefixes_array.length - 1);

        end

        device_model_capability = device_model.device_model_capabilities.where(firmware_prefix: model_capability_firmware_version).first

        
        if ( params[:parameter] != nil )

          device_model_firmware_prefixes = nil;
          device_model_capability_parameter = [] ;
          device_model_id = nil ;

          array_user_capability_parameter =  params[:parameter].gsub(/\s+/,"").split(',');          

          device_capabilties_hash = JSON.parse(device_model_capability.to_json);

          device_capabilties_hash.keys.each { |key|

            if ( key.casecmp("capability") == 0 )

              device_capabilties_hash[key].each { |capability_params|

                if ( array_user_capability_parameter.index(capability_params["param"].strip) != nil)

                  device_model_capability_parameter << capability_params; 

                end

              } ;

            
            elsif ( key.casecmp("firmware_prefix") == 0 )

              device_model_firmware_prefixes = device_capabilties_hash[key] ;

            elsif ( key.casecmp("id") == 0 )

              device_model_id = device_capabilties_hash[key] 
            
            end

          } ;

          # provide selected device capabilties information since there is no parameters present
          #present selected_device_model_capability.to_json, with: DeviceModelCapability::Entity
          status 200
          {
            "id" => device_model_id,
            "firmware_prefix" => device_model_firmware_prefixes,
            "capability" => device_model_capability_parameter
          }
        else
          # provide all device capabilties information since there is no parameters present
          present device_model_capability, with: DeviceModelCapability::Entity
        end

        

        
      
      end
    # Complete Query :- "Get the device capability information"

    # Query :- Share an own device with other users
    # Method :- GET
    # Parameters :-
    #         emails :- List of email
    # Response :-
    #         Return invitation status
    # 
    desc "Share an own device with other users"

      params do
        requires :emails, :desc => "Comma separated list of email ids."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':registration_id/share' do

        active_user = authenticated_user ;
        device = Device.where(registration_id: params[:registration_id]).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        forbidden_request! unless active_user.has_authorization_to?(:share, device );
      
        emails = params[:emails].split(',')
        invalid_emails = []
        sent_status = []
        data = []
        emails.each do |email|
          invalid_emails << email unless email.match(RubyRegex::Email)
        end

        invalid_request!(INVALID_EMAIL_FORMAT,"Invalid email ids: "+invalid_emails.join(",")) unless invalid_emails.empty? ;

        emails.each do |email|
          device_invitation = device.device_invitations.where(shared_by: active_user.id, shared_with: email).first
          if device_invitation
            DevicesAPI_v1.send_reminder(device_invitation)
          else
            device_invitation = device.device_invitations.new
            device_invitation.shared_by = active_user.id
            device_invitation.shared_with = email
            device_invitation.generate_invitation_key
            device_invitation.save!
            # Todo: Move to after create
            Thread.new{

              begin

                send_device_share_invitation(active_user.name,email,device_invitation.invitation_key)

                rescue Exception => exception
                ensure
                  ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                  ActiveRecord::Base.clear_active_connections! ;
              end
            }
          end
          sent_status << {
            :email => email,
            :status => Settings.email_sent_message
          }
        end
        status 200
        data <<
          {
            :device => {
              :device_id => device.id,
              :name => device.name,
              :registration_id => device.registration_id
            }
          }
        data << {:status => sent_status}
      
      end 
    # Complete Query :- Share an own device with other users

    # Query :- Accept the device sharing invitation
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return invitation status message
    #
    desc "Accept the device sharing invitation"

      params do
        requires :invitation_key, :desc => "Invitation key"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end  

      post 'accept_sharing_invitation' do

        active_user = authenticated_user ;
        
        status 200
        forbidden_request! unless active_user.has_authorization_to?(:accept, DeviceInvitation)

        device_invitation = DeviceInvitation.where(invitation_key: params[:invitation_key]).first
        not_found!(DEVICE_INVITATION_NOT_FOUND, "Device invitation key: " + params[:invitation_key].to_s) unless device_invitation
        invalid_request!(IVITATION_NOT_FOR_CURRENT_USER,Settings.share_with_mail_not_same) unless active_user.email == device_invitation.shared_with

        device = Device.where(id: device_invitation.device_id).first
        shared_device = device.shared_devices.new
        shared_device.shared_by = device_invitation.shared_by
        shared_device.shared_with = active_user.id
        shared_device.save!
        device_invitation.destroy
        "Invitation accepted"
      end
    # Complete query :- "accept_sharing_invitations"

    # Query :- Evaluate if any pending device sharing invitations are present and send reminder emails to the target users
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return query status message
    #
    desc "Evaluate if any pending device sharing invitations are present and send reminder emails to the target users"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		 end

      post 'send_sharing_invitation_reminder' do
      
        active_user = authenticated_user ;
        status 200
        forbidden_request! unless active_user.has_authorization_to?(:send, DeviceInvitation)

        device_invitations = DeviceInvitation.where("updated_at <= ?", Time.now-Settings.days_crossed.to_i.days )
        device_invitations.each do |device_invitation|
          Thread.new {

            begin
              DevicesAPI_v1.send_reminder(device_invitation)

              rescue Exception => exception
              ensure
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;
            end

          }
        end 
     end 
    # Complete query :- send_sharind_invitation_reminder

    # Query :- Remove sharing invitations of  own device for specified users
    # Method :- DELETE
    # Parameters :-
    #         emails :-  List of Email
    # Response :-
    #         Return "done" status message
    #
    desc "Remove sharing invitations of  own device for specified users"

      params do
        requires :emails,:type => String, :desc => "Comma seperated list of email ids"
      end

      delete ':registration_id/remove_sharing_invitations' do

        active_user = authenticated_user ;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:share, device)

        emails = params[:emails].split(',')
        device_invitations = device.device_invitations.where(shared_with: emails,shared_by: active_user.id) 
        device_invitations.each do |device_invitation|
          device_invitation.destroy
        end

        "Done"
      end
    # Complete query :- "remove_sharing_invitations"

    # Query :- Remove sharing of own device for specified users
    # Method :- DELETE
    # Parameters :-
    #         user_ids :-  List of User ID
    # Response :-
    #         Return "done" status message
    #
    desc "Remove sharing of own device for specified users"

      params do
        requires :user_ids,:type => String, :desc => "Comma seperated list of user ids"
      end

      delete ':registration_id/remove_sharing' do

        active_user = authenticated_user ;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        forbidden_request! unless active_user.has_authorization_to?(:share, device) ;

        user_ids = params[:user_ids].split(',') ;
        shared_devices = device.shared_devices.where(shared_with: user_ids,shared_by: active_user.id) ;
        shared_devices.each do |shared_device|
          shared_device.destroy
        end
        "Done"
      end
    # Complete Query :- "remove_sharing"

    # Query :- Set the extended attribute.
    # Method :- POST
    # Parameters :-
    #         key :-  Key 
    #         value :- Key value
    # Response :-
    #         Return extended attribute message
    #
    desc "Set the extended attribute."

      params do
        requires :key, :type => String, :desc => "Key should not not contain comma."
        requires :value, :type => String, :desc => "Value."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':registration_id/attribute' do

        active_user = authenticated_user ;
        device = Device.where(registration_id: params[:registration_id]).first
        
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:update, device)

        status 200

        invalid_parameter!("key") if ExtendedAttribute.invalid_key(params[:key]) ;
        
        extended_attribute = device.extended_attributes.where(key: params[:key]).first
        extended_attribute = device.extended_attributes.new unless extended_attribute

        extended_attribute.device_attribute_set_by_user(params[:key],params[:value]) ;
        send_command(CMD_ATTR_UPDATE,device,params[:key],nil)

        present extended_attribute, with: ExtendedAttribute::Entity
      end
    # Complete Query :- "extended attribute"

    # Query :- List of all extended attributes.
    # Method :- GET
    # Parameters :-
    #         key :-  Key 
    #         value :- Key value
    # Response :-
    #         Return extended attribute message
    #    
    desc "List of all extended attributes."

      params do
        optional :keys, :type => String, :desc => "Comma separated list of keys."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      get ':registration_id/attributes' do

        active_user = authenticated_user ;
        device = Device.where(registration_id: params[:registration_id]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:read_any, device)

        status 200
        
        key_array = params[:keys].split(',') if params[:keys]
        extended_attributes = params[:keys] ? device.extended_attributes.where(key: key_array) : device.extended_attributes
        
        present extended_attributes, with: ExtendedAttribute::Entity
      end
    # Complete Query :- "attributes"

 
    # Query :- Creates a talk back session
    # Method :- GET
    # Parameters :-
    #         None
    # Response :-
    #         Return extended attribute message
    # 
    desc "Creates a talk back session"
      
      params do
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':registration_id/create_talkback_session' do

        active_user = authenticated_user ;
        status 200

        device = Device.where(registration_id: params[:registration_id]).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        forbidden_request! unless active_user.has_authorization_to?(:create_talkback_session, device) ;

        relay_session = RelaySession.where("registration_id = ? ",params[:registration_id]).first

        if ( relay_session && ( (relay_session.updated_at + Settings.session_expiry.minutes) > Time.now.utc ))

          # return same relay session informtation

        else

          relay_session = RelaySession.new unless relay_session
          relay_session.registration_id = device.registration_id
          relay_session.session_key = relay_session.generate_session_key
          relay_session.stream_id = relay_session.generate_stream_id
          relay_session.save!

        end

         status 200
         present relay_session, with: RelaySession::Entity
      end
    # Complete Query :- "create_talkback_session" 

    # Query :- Signals device to start talk back session
    # Method :- POST
    # Parameters :-
    #         None
    # Response :-
    #         Return status message
    # 
    desc "Signals device to start talk back session"

      params do
        requires :session_key,:type => String, :length => Settings.session_key_length,:desc => "Session key"
        requires :stream_id,:type => String,:length => Settings.stream_id_length, :desc => "Stream id"
        requires :relay_server_ip, :validate_ip_address_format => true, :type => String, :desc => "Relay server ip"
        requires :relay_server_port, :validate_port_format => true, :type => Integer, :desc => "Relay server port"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post 'start_audio_session' do

        active_user = authenticated_user ;
        status 200

        relay_session = RelaySession.where(session_key: params[:session_key], stream_id: params[:stream_id]).first
        not_found!(RELAY_SESSION_NOT_FOUND, "Relay session") unless relay_session
        forbidden_request! unless active_user.has_authorization_to?(:start_audio_session, relay_session)

        device = Device.where(registration_id: relay_session.registration_id).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      
        # send command : action=start_talk_back&setup=8byteRelayServerIPHex.8bytePortStringinHex.64byteSessionKeyString.12byteStreamIDInString
        relay_server_ip_hex = relay_session.convert_ip(params[:relay_server_ip])
        talk_back_command = Settings.camera_commands.talk_back_command % [relay_server_ip_hex, "%08X" % params[:relay_server_port].to_s.upcase,relay_session.session_key, relay_session.stream_id] 
      
        send_command_over_stun(device, talk_back_command)
      end
    # Complete query :- "start_audio_session"

    # Query :- Signals device to close talk back session and clean all the related resources.
    # Method :- POST
    # Parameters :-
    #         session_key :- Session Key
    #         stream_id :- Stream ID
    # Response :-
    #         Return status message
    # 
    desc "Signals device to close talk back session and clean all the related resources."

      params do
        requires :session_key,:type => String,:length => Settings.session_key_length, :desc => "Session key"
        requires :stream_id,:type => String,:length => Settings.stream_id_length, :desc => "Channel id"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post 'stop_audio_session' do

        active_user = authenticated_user ;
        status 200

        relay_session = RelaySession.where(session_key: params[:session_key], stream_id: params[:stream_id]).first
        not_found!(RELAY_SESSION_NOT_FOUND, "Relay session") unless relay_session ;
        forbidden_request! unless active_user.has_authorization_to?(:stop_audio_session, relay_session) ;

        device = Device.where(registration_id: relay_session.registration_id).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
      
        relay_session.destroy
        send_command_over_stun(device, Settings.camera_commands.audio_stop_command) ;
      
      end
    # Complete Query :- "stop_audio_session"

    # Query :- Verify that Device upload token
    # Method :- POST
    # Parameters :-
    #         upload_token  :- Device upload token
    #         registration_id :- Device Registration ID
    # Response :-
    #         Send status information
    desc "Verify that device upload token"

      params do

        optional :upload_token,:desc => "Device upload token"
        requires :registration_id, :desc => "Device Registration ID"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post 'authenticate_device' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, Device) ;

        device_status = false;
        status_reason = AuthStatus::UNKNOWN_STATUS;

        device = Device.where(registration_id: params[:registration_id]).first ;


        if device

          # Device model number
          device_model_no    = device.registration_id[2..5];

          # Device is present in Hubble Eco system.
          if supportUploadTokenFeature!(device.firmware_version,device_model_no)
              
            # Device is supporting new version, so it is required that device should send authentication token
            # for validation process
            if params[:upload_token]

              if ( ( device.hasValid_UploadToken() ) && device.upload_token == params[:upload_token] )
                # valida device
                device_status = true;
                status_reason = AuthStatus::DEVICE_FOUND;
              else
                # validation failed for device
                status_reason = AuthStatus::INVALID_UPLOAD_TOKEN;
              end

            else
              # For new version of camera, Authentication is required.
              status_reason = AuthStatus::UPLOAD_TOKEN_REQUIRED;
            end

          else
            # For old version of camera, authenticaion is not required.
            device_status = true;
            status_reason = AuthStatus::DEVICE_FOUND;
          end
        else
          # Device is not found in eco system
          status_reason = AuthStatus::DEVICE_NOT_FOUND;
        end

        status 200
        {
          :auth_device_status => device_status,
          :auth_reason => status_reason
        }
      end
    # Complete Query :- Verify that user authentication token

    # Query :- Get Event Log
    # Method :- GET
    # Parameters :-
    #         event_name   :- Event Name
    #         user_id :- User ID
    # Response :-
    #         Return Event Log Informaton to application.
    
    desc "Get Device Event Log"

      params do

        optional :event_name, :desc => "Event Name"
        optional :user_id, :type => Integer,:desc => "User ID"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      get ':registration_id/event_log' do

        active_user = authenticated_user ;

        device = Device.where(registration_id: params[:registration_id]).first

        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
        forbidden_request! unless active_user.has_authorization_to?(:list, device) ;

        eventLog = nil ;

        if  ( params[:event_name] && params[:user_id] )
          eventLog = EventLog.where(registration_id: params[:registration_id],event_name: params[:event_name],user_id: params[:user_id]) ;

        elsif params[:event_name]
          eventLog = EventLog.where(registration_id: params[:registration_id],event_name: params[:event_name]) ;

        elsif params[:user_id]
          eventLog = EventLog.where(registration_id: params[:registration_id],user_id: params[:user_id]) ;

        else
          eventLog = EventLog.where(registration_id: params[:registration_id]) ;
        end

        status 200
        present eventLog, with: EventLog::Entity

      end
    # Complete Query :- "Event_Log"

    # Query :- Delete device events details
    # Method :- DELETE
    # Parameters :-
    #        event_details_id :- Event_details_id when device event details is generated
    # Response :-
    #         Return  Status

    desc "Delete one or more clips"
      params do
        requires :event_details_id,:type => String, :desc => "Comma separated list of event details ids." 
      end

      delete ':event_details_id/remove_event_files' do
        
        active_user = authenticated_user ;
        status 200

        if params[:event_details_id]
          
          event_details_ids = params[:event_details_id].split(',') ;
         
          DeviceEventDetail.destroy(event_details_ids)

        end

        "Clips deleted!"
      end
    
    # Complete Query :- "events"
    # Query :- Create a file session for Devcie which belongs to Current user
    # Method :- POST
    # Parameters :-
    #         client_type   :- Client type
    #         clip_name     :- clip_name
    #         md5_sum       :- md5_sum
    #         client_nat_ip :- NAT IP Address
    #         client_nat_port :- NAT IP port
    # Response :-
    #         Return session informaton to application.
    desc "Create a file session for a device that belongs to current user"

      params do

        requires :client_type, :desc => "Type of client. Either IOS,ANDROID or BROWSER"
        requires :clip_name, :desc => "Name of the clip to be streamed"
        requires :md5_sum, :desc => "MD5SUM of MD clip"
        optional :client_nat_ip, :validate_ip_address_format => true, :desc => "NAT IP address"
      end

      post ':registration_id/create_file_session' do
      
        active_user = authenticated_user ;

        device = Device.where(registration_id: params[:registration_id]).includes(:device_location).first ;

        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        forbidden_request! unless active_user.can_access_device?(:create_session, device,active_user ) ;

        bad_request!(MAC_ADDRESS_NULL,"Mac address is null") unless device.mac_address ;
        invalid_request!(DEVICE_INACTIVE, "Device is in inactive state") if device.plan_id == "inactive" ;

        relay_rtmp_ip = get_wowza_rtmp_address(device.device_location.remote_region_code) ;

        # create_sdses&ip=%s&id=%s&clip=%s&sum=%s
        command = Settings.camera_commands.get_sd_clip % [relay_rtmp_ip , device.generate_stream_name(), params[:clip_name],params[:md5_sum]  ]

        # send the get session key command to device
        response = send_command_over_stun(device,command);
        
        # response format
        # get_session_key: error=ERROR_NUMBER,session_key=<RTSP URL using NAT IP &PORT> ,talk_back_port = <talk_back_port>, mode=p2p_stun_rtsp
        # get_session_key: error=ERROR_NUMBER,session_key=<RTSP URL> ,talk_back_port = <talk_back_port>, mode=p2p_upnp_rtsp

        
          # check that device support new version server or not

          internal_error_with_data!(UNABLE_TO_CREATE_FILE_SESSION, ERRORS[response[:device_response][:device_response_code]], response) unless response[:device_response][:device_response_code] == 200 ;
          parsed_device_response = nil ;

          begin

            parsed_response = response[:device_response][:body] ;
            if parsed_response
              # it is require that we should move extra response character
              # Response from device after this :- "error=ERROR_NUMBER,session_key=<RTSP URL using NAT IP &PORT> ,talk_back_port = <talk_back_port>, mode=p2p_stun_rtsp"
              parsed_response = parsed_response.gsub("create_sdses: ",'');
            end
            # parse the response and get the key value pairs in a hash
            parsed_device_response = Rack::Utils.parse_nested_query(parsed_response.to_s,',')
            rescue Exception => NoMethodError
            internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Error parsing response from the device. The response from device is not in expected format.", response)
          end

          status_code=parsed_device_response["error"]
          
          unless  status_code.to_s == "200"
            
             case status_code
               
               when "601"
                failed_dependency!(INVALID_STREAM_ID)
                 
               when "602"  
                failed_dependency!(LIVE_STREAMING_IN_PROGRESS)
              
               when "603"
                failed_dependency!(INVALID_CLIP)
               
               when "604"
                failed_dependency!(INVALID_MD5SUM)
               
               when "605"
                failed_dependency!(SD_NOT_INSERTED)
               
               else
                internal_error_with_data!(UNABLE_TO_CREATE_SESSION, "Unable to create session. Invalid response received from device.", response)
          
            end #end of case
          end

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

           device.save_stream_name(parsed_device_response["session_key"]);

          status 200
          {
            :url => parsed_device_response["session_key"],
            :mode => parsed_device_response["mode"]
          }

   end

   # end of create_filesession query



    http_basic do |username, password|
      username == "device" && password == "device@123"
    end

    # Query :- Session Summary
    # Method :- POST
    # Parameters :-
    #         mode  :- Device Mode
    #         start_time :- Start time for session
    #         end_time :- End time for session
    #         session_time :- Session time
    # Response :-
    #         Send status message
    desc "Session summary"

      params do

        requires :mode, :type => String, :desc => "Mode ( relay OR p2p OR stun OR upnp) "
        optional :start_time
        optional :end_time
        requires :session_time, :type => Integer
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':registration_id/session_summary' do

        # active_user = authenticated_user ;

        device = Device.where(registration_id: params[:registration_id]).first ;
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device ;
        # forbidden_request! unless current_user.has_authorization_to?(:stop_audio_session, relay_session)

        status 200

        case params[:mode]

          when "p2p","1", "stun","upnp"
            device.upnp_usage += params[:session_time]
            device.upnp_count += 1

          when "relay","3"
            device.relay_usage += params[:session_time]
            device.relay_count += 1
            device.latest_relay_usage = params[:session_time]
        else
          invalid_parameter!("mode")

        end

        device.last_accessed_date = Time.now
        device.save!
      end
    # Complete Query :- Session Summary
    
  end
  # End of "devices" API Query

  # Module :- session_key
  # Description :- Generate Session key
  def self.session_key(value)
    sha256 = Digest::SHA256.new
    sha256.update (value)
    session_key = sha256.hexdigest.upcase
  end

  # Module :- generate_channel_id
  # Description :- Provide channel ID
  def self.generate_channel_id(length)
    rand.to_s[2...length +2].to_i
  end

  # Module :- send_reminder
  # Description :- Send remainder inviation
  def self.send_reminder(device_invitation)
    device_invitation.reminder_count +=1
    device_invitation.save!
    user = User.where(id: device_invitation.shared_by).first  
    send_device_share_invitation(user.name,device_invitation.shared_with,device_invitation.invitation_key) if user
  end 

  # Module :- convaertIP
  # Description :- Generate IP address in HEX format
  def self.convertIP(ip)
    ip_reverse = ip.to_s.split('.').reverse.join('.')
    ip_hex = IP.new(ip_reverse).to_hex.upcase
  end 

  def get_sdcard_data(event)
    device_event_details = DeviceEventDetail.where(device_event_id: event.id)  
    playlist = [];
    device_event_details.each {|clip|
        item = PlaylistItem.new
        item.id = clip.id
        item.image = get_snap_url(event)
        item.clip_name= clip.clip_name
        item.md5_sum= clip.md5_sum
        playlist << item
    }
      if playlist.length == 0
      item = PlaylistItem.new ;
      item.id = "";
      item.image = event.event_code;
      item.clip_name= "";
      item.md5_sum= "";
      playlist << item

    end # if

    # Return created playlist for caller.
    playlist  

  end

  mount DevicesCookerAPI_v1

end
