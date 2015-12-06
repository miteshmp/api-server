# This file contains definition of AWS related modules.

AWS.eager_autoload!

module AwsHelper
  include AlcatelHelper

  # Module :- Create AWS Folders
  # It  will create folders in AWS S3 Bucket.
  def create_aws_folders(device)

    # Create S3 objects
    s3 = AWS::S3.new
    # Initialize "path" for folders
    path = Settings.file_path

    # Initialize "bucket" for "Snap" folder
    bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path % [device.registration_id,Settings.snaps_path] +'/file.tmp'] ;
    bucket.write(path);

    # Initialize "bucket" for "Clips" Folder
    bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path % [device.registration_id,Settings.clips_path] +'/file.tmp'];
    bucket.write(path);

    # Initialize "bucket for "Logs" folder
    bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path  % [device.registration_id,Settings.logs_path] +'/file.tmp'];
    bucket.write(path);

  end

  def collect_events_data(device_events, video_period)
    event_threads = []
    events = []
    semaphore = Mutex.new
    device_events.each do |event|
      event_threads << Thread.new {
        begin
          data = get_playlist_data(event.device, event.event_code, (video_period.to_i.days.ago..Time.now.utc).cover?(event.time_stamp)) if (event.alert == EventType::MOTION_DETECT_EVENT && event.event_code)
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
    events.sort_by { |k| k[:time_stamp] }
  end


  # Module : get_playlist
  def get_playlist(registration_id, event_key, snap_url, has_motion_video)

    #Initialize "playlist" array for snaps
    playlist = [];

    #Initialize "s3" objects
    s3 = AWS::S3.new;

    # Get Event key from every_key parameters
    event_key = event_key.split('.')[0];

    #  Get all snaps collection from S3 Bucket
    collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_events_path % [ registration_id, Settings.clips_path, event_key]);

    collection.each {|clip|

      # Check that clip is end_with "flv" or "mp4" or not.
      if clip.key.downcase.end_with?(".flv",".mp4")

        item = PlaylistItem.new
        item.image = snap_url
        if has_motion_video
          item.file = clip.url_for(:read, :secure => false, :expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME ).to_s 
        end
        item.title = ""
        playlist << item

      end # if

    } # collection.each

    # PlayList Length is zero then Create new empty PlayList item
    if playlist.length == 0

      item = PlaylistItem.new ;
      item.image = snap_url ;
      item.file = "" ;
      item.title = "" ;
      playlist << item

    end # if

    # Return created playlist for caller.
    playlist

  end
  # Completed :- "get_playlist"

  # Module :- "delete_folder"
  # Description :- Delete folder based on registration ID

  def delete_folder

    s3 = AWS::S3.new ;
    bucket = AWS::S3.new.buckets[Settings.s3_bucket_name] ;
    bucket.objects.with_prefix(Settings.s3_device_folder % [params[:registration_id]]).delete_all ;

  end
  # Completed :- "delete_folder"

  # Module :- delete_all_s3_events
  # Description :- it will delete all events from S3 Folder
  def delete_all_s3_events(registration_id)

    Thread.new {

      begin
        s3 = AWS::S3.new;

        snap_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_snap_folder % [registration_id]);
        snap_collection.delete_all ;

        clips_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_clip_folder % [registration_id]);
        clips_collection.delete_all ;

        bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path % [registration_id,Settings.snaps_path]+'/file.tmp'] ;
        bucket.write(:file => Settings.temp_file_path);


        bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path % [registration_id,Settings.clips_path]+'/file.tmp'];
        bucket.write(:file => Settings.temp_file_path);

      rescue Exception => exception
      ensure
        # Active record connections open when Thread is created
        ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
        ActiveRecord::Base.clear_active_connections! ;
      end

    }

  end

  # Module :- "get_logs"
  # Description:- Get logs based on device
  def get_logs(device)

    logs = [] ;
    logs_threads = [] ;
    list = [] ;
    s3 = AWS::S3.new ;

    collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_logs_path % device.registration_id) ;

    # Filter logs whose filename start only with either mac_address or registration_id
    collection.each do |log|
      list <<  log unless log.key.split('/')[3].start_with?(Settings.tmp_filename)
    end

    sorted_list = list.sort_by { |x| x.last_modified }

    latest_logs_list = sorted_list.reverse ;
    latest_logs_list_hash = Hash[latest_logs_list.map.with_index.to_a].invert ;

    latest_logs_list_hash.each {   |index,log|
      logs_threads << Thread.new {
        log_url = log.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s
        latest_logs_list_hash[index] = log_url  ;
      } # logs_threads
    } # latest_logs_list_hash.each
    logs_threads.each {|thr| thr.join}

    latest_logs_list_hash.values ;


  end
  # Complete :- "get_logs"

  # Module :- Send_Push_Notification
  # Description :- It will send notification to SNS based on ARN.
  def send_push_notification(target_arn,device,type,alert,device_type=EventType::NOT_AVAILABLE,parent_device_name=nil)

    options = Hash.new ;

    alert_message = "";
    options[:target_arn] = target_arn;
    event_device_name = device ? device.name : EventType::NOT_AVAILABLE ;

    case alert

    when EventType::SOUND_EVENT.to_s, EventType::SOUND_EVENT
      alert_message = EventType::SOUND_EVENT_MESSAGE + event_device_name  ;

    when EventType::HIGH_TEMP_EVENT.to_s, EventType::HIGH_TEMP_EVENT
      alert_message = EventType::HIGH_TEMP_EVENT_MESSAGE + event_device_name ;

    when EventType::LOW_TEMP_EVENT.to_s, EventType::LOW_TEMP_EVENT
      alert_message = EventType::LOW_TEMP_EVENT_MESSAGE + event_device_name ;

    when EventType::MOTION_DETECT_EVENT.to_s, EventType::MOTION_DETECT_EVENT
      alert_message = EventType::MOTION_DETECT_EVENT_MESSAGE + event_device_name ;

    when EventType::UPDATING_FIRMWARE_EVENT.to_s, EventType::UPDATING_FIRMWARE_EVENT
      alert_message =  EventType::UPDATING_FIRMWARE_EVENT_MESSAGE + event_device_name ;

    when EventType::SUCCESS_FIRMWARE_EVENT.to_s, EventType::SUCCESS_FIRMWARE_EVENT
      alert_message = EventType::SUCCESS_FIRMWARE_EVENT_MESSAGE + event_device_name ;

    when EventType::RESET_PASSWORD_EVENT.to_s,EventType::RESET_PASSWORD_EVENT
      alert_message = EventType::RESET_PASSWORD_EVENT_MESSAGE % [ device_type ];

    when EventType::DEVICE_REMOVED_EVENT.to_s,EventType::DEVICE_REMOVED_EVENT
      alert_message = EventType::DEVICE_REMOVED_EVENT_MESSAGE % [ event_device_name ];

    when EventType::DEVICE_ADDED_EVENT.to_s,EventType::DEVICE_ADDED_EVENT
      alert_message = EventType::DEVICE_ADDED_EVENT % [ event_device_name ];

    when EventType::SENSOR_PAIRED_EVENT.to_s,EventType::SENSOR_PAIRED_EVENT
      alert_message = EventType::SENSOR_PAIRED_EVENT_MESSAGE  % [ event_device_name ];  

    when EventType::SENSOR_PAIRED_FAIL_EVENT.to_s,EventType::SENSOR_PAIRED_FAIL_EVENT
      alert_message = EventType::SENSOR_PAIRED_FAIL_EVENT_MESSAGE  % [ event_device_name ];  

    when EventType::CHANGE_TEMPERATURE_EVENT.to_s,EventType::CHANGE_TEMPERATURE_EVENT

      device_temperature = params[:val].to_s.split(EventType::TEMPERATURE_SPLIT_SPECIFIER);

      if ( device_temperature.length == EventType::LENGTH_TEMPERATURE_INFO )

        alert_message = EventType::CHANGE_TEMPERATURE_EVENT_MESSAGE % [ device_temperature[0].to_s, device_temperature[1].to_s, device_temperature[2].to_s,event_device_name ] ;

      else

        alert_message = EventType::DEFAULT_CHANGE_TEMPERATURE_EVENT_MESSAGE % [ event_device_name ]
      end

    when EventType::DOOR_MOTION_DETECT_EVENT.to_s,EventType::DOOR_MOTION_DETECT_EVENT
      alert_message = EventType::DOOR_MOTION_DETECT_EVENT_MESSAGE % [ event_device_name, parent_device_name ]

    when EventType::PRESENCE_DETECT_EVENT.to_s,EventType::PRESENCE_DETECT_EVENT
      alert_message = EventType::PRESENCE_DETECT_EVENT_MESSAGE % [ event_device_name, parent_device_name ]
      
    end

    options[:message_structure] = EventType::PUSH_NOTIFICATION_MESSAGE_STRUCTURE;

    event_value = params[:val] ? params[:val] : device_type ;
    event_device_registration_id = device ? device.registration_id : EventType::NOT_AVAILABLE ;
    event_ftp_url = params[:ftpUrl] ? params[:ftpUrl] : EventType::NOT_AVAILABLE ;

    if type.upcase == EventType::PUSH_NOTIFICATION_TYPE_APNS.upcase

      data = {
        :aps =>
        {
          :'content-available' => 1,  # content-available given in single quotes to escape dash(-)
          :alert => alert_message,
          :sound => EventType::DEFAULT_SOUND_KEY_IOS_NOTIFICATION
        },
        :alert => alert,
        :val => event_value,
        :mac => event_device_registration_id,
        :time => Time.now,
        :cameraname => event_device_name
      }.to_json.to_s

      options[:message] =  {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS => data,
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS_SANDBOX => data
      }.to_json


    elsif type.upcase == EventType::PUSH_NOTIFICATION_TYPE_GCM.upcase


      data =  {
        :data =>
        {
          :alert => alert,
          :val => event_value,
          :mac => event_device_registration_id,
          :time => Time.now,
          :cameraname => event_device_name,
          :ftp_url => event_ftp_url
        }
      }.to_json.to_s

      options[:message] = {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_GCM => data
      }.to_json

    end

    response = publish_notification(options)

  end
  # Complete :- "send_push_notification"

  def publish_notification(options)
    begin
      sns = AWS::SNS::Client.new
      sns.publish(options);
    rescue Exception => exception
      Rails.logger.error "Exception Occured :- while sending push notification: #{exception}"
    end
  end

  def send_subscription_notification(device, msg, message_type, freetrial_expiry_days, subscription_name)
    if device.present?
      user = device.user
      msg_aps = { 
        :aps => {
          :'content-available' => 1,  # content-available given in single quotes to escape dash(-) 
          :alert => msg, 
          :sound => EventType::DEFAULT_SOUND_KEY_IOS_NOTIFICATION 
          },
        :alert => EventType::CUSTOM_MESSAGE_EVENT,
        :hubble_message_type => message_type,
        :subscription_name => subscription_name.present? ? subscription_name : device.plan_id,
        :free_trial_expires_in_x_days => freetrial_expiry_days,
        :camera_name => device.name ? device.name : EventType::NOT_AVAILABLE,
        :registration_id => device.registration_id,
        :url => Settings.subscription_plan_url,
        :Message => msg,
        # message field is case sensitive & differs in older iOS & Android app and hence duplicated for backward compatibility
        :message => msg,
        :time => Time.now
      }.to_json.to_s
      message_apns = {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS => msg_aps,
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS_SANDBOX => msg_aps
      }
      message_gcm = {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_GCM => {
          :data => {
          :alert => EventType::CUSTOM_MESSAGE_EVENT,
          :hubble_message_type => message_type,
          :subscription_name => subscription_name.present? ? subscription_name : device.plan_id,
          :free_trial_expires_in_x_days => freetrial_expiry_days,
          :camera_name => device.name ? device.name : EventType::NOT_AVAILABLE,
          :registration_id => device.registration_id,
          :url => Settings.subscription_plan_url,
          :Message => msg,
          # message field is case sensitive & differs in older iOS & Android app and hence duplicated for backward compatibility
          :message => msg,
          :time => Time.now
          }
        }.to_json.to_s
      }
      subscription_gcm_apps = SUBSCRIPTION_SUPPORTED_APPS["gcm"]
      subscription_apns_apps = SUBSCRIPTION_SUPPORTED_APPS["apns"]
      target_arn_gcm = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1, app_unique_id: subscription_gcm_apps).map(&:sns_endpoint)
      target_arn_apns = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2, app_unique_id: subscription_apns_apps).map(&:sns_endpoint)
      notification_threads = []
      # Send Push notification for GCM
      target_arn_gcm.each do |target_arn|
        notification_threads << Thread.new {
          begin
            res = push_subscription_message(message_gcm.to_json, target_arn)
          ensure
            ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
            ActiveRecord::Base.clear_active_connections! ;
          end
        }
      end

      # Send Push notification for Apple
      target_arn_apns.each do |target_arn|
        notification_threads << Thread.new {
          begin
            res = push_subscription_message(message_apns.to_json, target_arn)
          ensure
            ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
            ActiveRecord::Base.clear_active_connections! ;
          end
        }
      end
    end

  end

  def push_subscription_message(data, target_arn)
    options = Hash.new
    options[:message_structure] = EventType::PUSH_NOTIFICATION_MESSAGE_STRUCTURE
    options[:message] = data
    options[:target_arn] = target_arn
    publish_notification(options)
  end

  # Module :- "register_for_mobile_push"
  # Description :- Register mobile notification based on registration
  def register_for_mobile_push(platform_endpoint, registration_id)

    sns = AWS::SNS::Client.new ;
    options = Hash.new ;

    options[:platform_application_arn] = platform_endpoint ;
    options[:token] = registration_id ;

    begin
      endpoint = sns.create_platform_endpoint(options) ;
    rescue AWS::SNS::Errors::InvalidParameter => exception
      bad_request!(INVALID_PARAMETER,exception.message) ;
    end

    endpoint[:endpoint_arn];

  end
  # Completed :- "register_for_mobile_push"

  # Module :- "delete_registered_notification_endpoint"
  # Description :- It should delete endpoint based on registration ID.
  #               This condition is required when User logout from application.
  def delete_registered_notification_endpoint(endpoint_arn)

    sns = AWS::SNS::Client.new ;
    options = Hash.new ;
    # class "AWS::Core::Response"
    response = nil ;

    if endpoint_arn

      options[:endpoint_arn] = endpoint_arn ;

      begin

        response = sns.delete_endpoint(options) ;
      rescue AWS::SNS::Errors::InvalidParameter => exception
        bad_request!(INVALID_PARAMETER,exception.message) ;

      end
      # Return status about deleting endpoint
      ( response != nil && ( response.http_response.status == 200 ) ) ? true : false;

    else
      return false;
    end

  end
  # Completed :- "delete_registered_notification_endpoint"

  # Module :- "batch_notification"
  # Description :- Send batch notification to target Device
  def batch_notification(target_arn,device,type,notification_type)

    message = get_message(type);
    options = Hash.new ;

    options[:target_arn] = target_arn ;
    options[:message_structure] = EventType::PUSH_NOTIFICATION_MESSAGE_STRUCTURE ;

    if notification_type == EventType::PUSH_NOTIFICATION_TYPE_APNS
      data =
      {
        :aps =>
        {
          :'content-available' => 1,  # content-available given in single quotes to escape dash(-)
          :message => message,
          :mac => device.registration_id
        }
      }.to_json.to_s

      options[:message] =
      {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS => data,
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS_SANDBOX => data
      }.to_json

    elsif notification_type == EventType::PUSH_NOTIFICATION_TYPE_GCM
      data =
      {
        :data =>
        {
          :message => message,
          :mac => device.registration_id
        }
      }.to_json.to_s

      options[:message] =
      {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_GCM => data
      }.to_json
    end

    response = publish_notification(options)

  end
  # Complete :- "batch_notification"

  # Module :- "send_batch_notification"
  def send_batch_notification(user,device,type)

    target_arn_gcm_list = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint) ;
    target_arn_apns_list = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint) ;

    notification_threads = [] ;

    target_arn_gcm_list.each do |target_arn|

      notification_threads << Thread.new {

        begin
          batch_notification(target_arn,device,type,EventType::PUSH_NOTIFICATION_TYPE_GCM) ;

        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end

      }
    end

    target_arn_apns_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          batch_notification(target_arn,device,type,EventType::PUSH_NOTIFICATION_TYPE_APNS) ;

        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end
      }
    end

  end
  # Complete :- "send_batch_notification"

  # Module :- send_notification
  # Description :- Send alert notification to all User's application End point ( iOS or Android)
  def send_notification(user,device,alert,device_type=EventType::NOT_AVAILABLE,parent_device_name=nil)

    # Return parameter list.
    notification_status = false;
    response_code = HttpStatusCode::SUCCESS ;  # response code should be 200 ( default)
    response_message  = "" ;

    if device
      # Send notifications to the apps supported by the device model.

      device_model_number = device.registration_id[2..5]

      begin
        gcm_apps = MODEL_SUPPORTED_APPS[device_model_number][:gcm]
        apns_apps = MODEL_SUPPORTED_APPS[device_model_number][:apns]
      rescue
        NewRelic::Agent.notice_error("Apps with the supported model not found",
            :uri => env["REQUEST_PATH"],              
            :custom_params => {"URL" => env["HTTP_HOST"],"MODEL_NO" => device_model_number })
      end 

      # get all the registration ids into one array
      # note the map(&) method call at the end
      target_arn_gcm_list = user.apps.select([:sns_endpoint,:notification_type,:app_unique_id]).where(app_unique_id: gcm_apps).map(&:sns_endpoint)
      target_arn_apns_list = user.apps.select([:sns_endpoint,:notification_type,:app_unique_id]).where(app_unique_id: apns_apps).map(&:sns_endpoint)

    else
      # Get user's gcm devices endpoints
      target_arn_gcm_list = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint)
      # Get user's ios devices endpoints
      target_arn_apns_list = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint)
    end  
    # Notification Thread List
    notification_threads = [] ;

    # Send Push notification for GCM
    target_arn_gcm_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          send_push_notification(target_arn,device,EventType::PUSH_NOTIFICATION_TYPE_GCM,alert,device_type,parent_device_name) ;
        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end
      }
    end

    # Send Push notification for Apple
    target_arn_apns_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          send_push_notification(target_arn,device,EventType::PUSH_NOTIFICATION_TYPE_APNS,alert,device_type,parent_device_name) ;
        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end
      }
    end

    notification_status = true;
    response_message = target_arn_gcm_list.count.to_s.concat(":").concat(target_arn_apns_list.count.to_s);


  # return information about notification,
  return [ notification_status, response_code, response_message]

  end
  # Complete Module :- send_notification

  # Module name :- batch_notification
  # Description :-
  #            Send message to application which belongs to user
  def batch_notification(user,message)

    # Get Google Notification URI belongs to user
    target_arn_gcm_list = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint) ;

    # Get Apple Notificaton URI belongs to user
    target_arn_apns_list = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint) ;

    notification_threads = [] ;

    # Send every Google Notification
    target_arn_gcm_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          notify(target_arn,message,EventType::PUSH_NOTIFICATION_TYPE_GCM) ;

        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end

      }

    end

    # Send every APNS notification
    target_arn_apns_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          notify(target_arn,message,EventType::PUSH_NOTIFICATION_TYPE_APNS) ;

        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end
      }

    end

  end
  # Complete Module

  # Module name :- notify
  # Description :- It should send message to target ARN
  def notify(target_arn,message,notification_type)

    options = Hash.new ;
    options[:target_arn] = target_arn ;
    customAlertNotifcationID = Settings.custom_message_alert.to_s ;

    data =  {
      :message => message
    }.to_json

    options[:message_structure] = EventType::PUSH_NOTIFICATION_MESSAGE_STRUCTURE ;

    if notification_type == EventType::PUSH_NOTIFICATION_TYPE_APNS

      data =
      {
        :aps =>
        {
          :'content-available' => 1,  # content-available given in single quotes to escape dash(-)
          :alert => message,
          :sound => EventType::DEFAULT_SOUND_KEY_IOS_NOTIFICATION
        },
        :alert => customAlertNotifcationID,
        :message => params[:message],
      }.to_json.to_s

      options[:message] =
      {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS => data,
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS_SANDBOX => data
      }.to_json

    elsif notification_type == EventType::PUSH_NOTIFICATION_TYPE_GCM

      data =
      {
        :data =>
        {
          :message => message,
          :alert => customAlertNotifcationID,
        }
      }.to_json.to_s

      options[:message] =
      {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_GCM => data
      }.to_json
    end

    response = publish_notification(options)

  end
  # Complete  :- notify

  # Module :- "send_custom_notification"
  def send_custom_notification(user)

    target_arn_gcm_list = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint) ;
    target_arn_apns_list = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint) ;

    notification_threads = [] ;

    target_arn_gcm_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          custom_notification(target_arn,EventType::PUSH_NOTIFICATION_TYPE_GCM) ;
        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end

      }
    end

    target_arn_apns_list.each do |target_arn|

      notification_threads << Thread.new {

        begin

          custom_notification(target_arn,EventType::PUSH_NOTIFICATION_TYPE_APNS);
        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end
      }
    end

  end
  # Complete :- "send_custom_notification"

  # Module :- "custom_notification"
  def custom_notification(target_arn,type)

    options = Hash.new ;

    options[:target_arn] = target_arn ;
    options[:message_structure] = EventType::PUSH_NOTIFICATION_MESSAGE_STRUCTURE ;
    customAlertNotifcationID = EventType::CUSTOM_MESSAGE_EVENT.to_s ;


    if type == EventType::PUSH_NOTIFICATION_TYPE_APNS


      data =
      {
        :aps =>
        {
          :'content-available' => 1,  # content-available given in single quotes to escape dash(-)
          :alert => params[:message],
          :sound => EventType::DEFAULT_SOUND_KEY_IOS_NOTIFICATION
        },
        :alert => customAlertNotifcationID,
        :message => params[:message],
        :url => params[:url]
      }.to_json.to_s

      options[:message] =
      {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS => data,
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_APNS_SANDBOX => data
      }.to_json

    elsif type == EventType::PUSH_NOTIFICATION_TYPE_GCM

      data =
      {
        :data =>
        {
          :alert => customAlertNotifcationID,
          :message => params[:message],
          :url => params[:url]
        }
      }.to_json.to_s

      options[:message] =
      {
        EventType::PUSH_NOTIFICATION_MESSAGE_TYPE_GCM => data
      }.to_json
    end

    response = publish_notification(options)

  end
  # Complete :- "custom_notification"

  # Module :- "get_message"
  def get_message(type)
    message = ""
    case type
    when "deactivate"
      message = Settings.deactivation_message ;
    when "upgrade"
      message = Settings.upgrade_message ;
    end
  end
  # Complete :- "get_message"

  # Module :- "upload_test_report_to_s3"
  # Description :- Upload test report into S3
  def upload_test_report_to_s3(file,model_no)
    s3 = AWS::S3.new ;
    file_name = file.filename ;
    bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_device_masters_path % [model_no] + '/' + file_name] ;
    bucket.write(file.tempfile) ;
  end
  # Complete :- "upload_test_report_to_s3"

  # Module :- "upload_capability_to_s3"
  # Description :- Upload capability file into S3 folder
  def upload_capability_to_s3(file,firmware_prefix)

    s3 = AWS::S3.new ;
    file_name = file.filename ;
    bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_device_model_capabilities_path % [firmware_prefix] + '/'+ file_name] ;
    bucket.write(file.tempfile);

  end
  # Complete :- "upload_capability_to_s3"

  # Module :- "upload_type_capability_to_s3"
  # Description :- Upload  type capability file into S3 folder
  def upload_type_capability_to_s3(file,type_code)

    s3 = AWS::S3.new  ;
    file_name = file.filename ;
    bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_device_types_capabilities_path % [type_code] + '/' + file_name];
    bucket.write(file.tempfile) ;

  end
  # Complete :- "upload_type_capability_to_s3"

  # Module :- "get_playlist_data"
  # Description :- Get all playlist data
  def get_playlist_data(device, event_data, has_motion_video)
    
    s3 = AWS::S3.new ;
    data = [] ;
    snap_url =  nil ;

    snap = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_event_snap_path % [device.registration_id, event_data]] ;
    snap_url = snap.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s;
    data = get_playlist(device.registration_id, event_data, snap_url, has_motion_video);
    return data

  end

  # Module :- "get_snap_url"
  # Description :- Construct snap url based on device event
  def get_snap_url(event)
    
    s3 = AWS::S3.new ;
    data = [] ;
    snap_url =  nil ;

    snap = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_event_snap_path % [event.device.registration_id, event.event_code]] ;
    snap_url = snap.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s;

  end

  # Completed :- "get_playlist_data"

  # Module :- "get_alert_name"
  # Description :- Return alert message based on alert type
  def get_alert_name(alert)
    
    if alert == 1
      "sound detected"
    elsif alert == 2
      "high temperature detected"  
    elsif alert == 3
      "low temperature detected"
    elsif alert == 4
      "motion detected"
    elsif alert == 21
      "door motion detected"
    elsif alert == 22
      "presence detected"    
    elsif alert == 23
      "Sensor added"
     elsif alert == 24
      "Failed to add sensor"       
    end
  
  end
  # Complete :- "get_alert_name"

  # Module :- "delete_objects"
  def delete_objects(devices,limit)

    s3 = AWS::S3.new ;
    semaphore = Mutex.new ;

    delete_events_threads = [] ;
    data = [] ;

    total = devices.count ;

    devices.each do |device|

      delete_events_threads << Thread.new {

        begin

          item = delete_s3_events(device,limit)
          semaphore.synchronize {
            data << item if item
          }

        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
        end

      }
    end # do
    delete_events_threads.each { |thr| thr.join } 
    send_s3_folder_cleanup_report(data) if  ( data.length > 0 )

  end
  # Completed :- "delete_objects"

  # Module :- "delete_s3_events"
  def delete_s3_events(device,limit)

    s3 = AWS::S3.new ;
    clips_count = 0 ;

    device_events = device.device_events.select('id,event_code,deleted_at').where(alert: EventType::MOTION_DETECT_EVENT);
    # Find the number of events to be deleted
    delete_events_count = (device.device_events.count - limit) ;

    if delete_events_count > 0

      # Device events to delete
      device_events_to_delete = device.device_events.first(delete_events_count) ;

      device_events_to_delete.each do |device_event|

        if device_event.event_code

          snap = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_event_snap_path % [device.registration_id,device_event.event_code]];
          snap.delete;
          clips_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_clip_path % [device.registration_id, device_event.event_code.split('.')[0]]);
          clips_collection.each do |clip|
            clips_count = clips_count + 1;
            clip.delete;
          end

        end

        # Soft delete event
        device_event.destroy
      end

      return
      {
        :registration_id => device.registration_id,
        :deleted_clips => clips_count,
        :deleted_snaps => delete_events_count
      }
    end

  end
  # Complete :- "delete_s3_events"

  # Module :- "get_limit"
  def get_limit(subscription_type)
    STORAGE_LIMIT[subscription_type]
  end
  # Complete :- "get_limit"

  # Module :- "delete_events"
  def delete_events(registration_id,event_code)

    s3 = AWS::S3.new;

    snap_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_snap_path % [registration_id, event_code]);
    snap_collection.delete_all ;

    clips_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_clip_path % [registration_id, event_code]);
    clips_collection.delete_all ;

    # clips_collection.each {|clip|
    #  clip.delete;
    # }

  end
  # Complete :- "delete_events"



  # Method :- "device_logo_is_exist"
  # Description :- verify that Device snap which is uploaded by User is existed or not.
  #                If device logo is existed then it will return URL with status message
  def device_logo_is_exist! ( registration_id )

    status = false;
    device_logo_url = nil;
    snap_modified_at = nil;

    begin
      s3 = AWS::S3.new ;
      bucket = s3.buckets[Settings.s3_bucket_name].objects[Settings.devices_path % [registration_id] + Settings.image_path + '/' + Settings.image_name ];

      if bucket.exists?
        status = true;
        snap_modified_at = (bucket.last_modified.to_i).to_s ;
        device_logo_url = bucket.url_for(:read, :secure => false,:expires => AWSConfiguration::S3_OBJECT_EXPIRY_TIME).to_s;
      end
      # Handle exception occured for Amazon S3
    rescue Errors::NoSuchKey => exception
      print exception;
    rescue Exception => exception
      print exception;

    end
    {
      :status => status,
      :logo_url => device_logo_url,
      :snap_modified_time => snap_modified_at
    }
  end
  # Complete method :- "device_logo_is_exist"

end
# Complete :- AwsHelpers

