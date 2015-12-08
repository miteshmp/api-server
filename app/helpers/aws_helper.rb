AWS.eager_autoload!
module AwsHelper
	def create_aws_folders(device)
   s3 = AWS::S3.new 
   path = Settings.file_path    
   b = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path % [device.registration_id,Settings.snaps_path] +'/file.tmp']
   b.write(path)
   b = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path % [device.registration_id,Settings.clips_path] +'/file.tmp']
   b.write(path) 
   b = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_devices_path  % [device.registration_id,Settings.logs_path] +'/file.tmp']
   b.write(path)
 end   



 def get_playlist(registration_id,event_key,snap_url)
   playlist = []
   s3 = AWS::S3.new 
   event_key = event_key.split('.')[0]
   collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_events_path % [ registration_id, Settings.clips_path, event_key])
   collection.each {|clip|
    if clip.key.downcase.end_with?(".flv",".mp4")                
      item = PlaylistItem.new    
      item.image = snap_url
      item.file = clip.url_for(:read, :secure => false).to_s
      item.title = "" 
      playlist << item           
      end # if

   } # collection.each
   if playlist.length == 0
    item = PlaylistItem.new
    item.image = snap_url
    item.file = ""
    item.title = ""

    playlist << item
    end # if
    playlist
  end 

  def delete_folder
    s3 = AWS::S3.new 
    
    bucket = AWS::S3.new.buckets[Settings.s3_bucket_name]  
    bucket.objects.with_prefix(Settings.s3_device_folder % [params[:registration_id]]).delete_all    
  end 


  def get_logs(registration_id)
    logs = []
    logs_threads = []
    s3 = AWS::S3.new 
    collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_logs_path % [registration_id,registration_id])  
    sorted_list = collection.sort_by { |x| x.last_modified } 
    latest_logs_list = sorted_list.reverse
    latest_logs_list_hash = Hash[latest_logs_list.map.with_index.to_a].invert  
    
    latest_logs_list_hash.each {   |index,log|
      logs_threads << Thread.new {
        log_url = log.url_for(:read, :secure => false).to_s
        latest_logs_list_hash[index] = log_url
      } # logs_threads 
    } # latest_logs_list_hash.each
    logs_threads.each {|thr| thr.join}
    
    latest_logs_list_hash.values
    
  end 

 
    def send_push_notification(target_arn,device,type)
     sns = AWS::SNS::Client.new
     options = Hash.new



     options[:target_arn] = target_arn
     
     case params[:alert]
     when "1",1
      alert = "Sound detected from " + device.name
      when "2",2 
        alert = "High temp from " +device.name 
      when "3",3 
        alert = "Low temp from " + device.name 
      when "4",4
        alert = "Motion detected from " + device.name
      end 

      
      
    
       options[:message_structure] = "json"

       if type == "apns"
          data = {:aps => {:alert => alert,:sound =>"default"},
            :alert => params[:alert],
            :val => params[:val],
            :mac => device.registration_id,
            :time => Time.now,
            :cameraname => device.name,
            :ftp_url => params[:ftpUrl]
            }.to_json.to_s
      
          options[:message] =  {
                  "APNS_SANDBOX" => data
                  }.to_json
      elsif type == "gcm"
            data =  { :data =>{
                                  :alert => params[:alert],         
                                  :val => params[:val],
                                  :mac => device.registration_id,                                  
                                  :time => Time.now,
                                  :cameraname => device.name,
                                  :ftp_url => params[:ftpUrl] }  }.to_json.to_s

             options[:message] =  {
                  "GCM" => data
                  }.to_json
      end  
                                
      p data
     
      begin
        response = sns.publish(options)
      rescue Exception => e 
        p "exception...................................." 
        p e
       end 
     

    end



    def register_for_mobile_push(notification_type, registration_id)
      sns = AWS::SNS::Client.new
      options = Hash.new

      platform_endpoint = nil 

      if notification_type == "gcm"
        platform_endpoint = Settings.sns_platform_endpoint.gcm
      else 
       platform_endpoint = Settings.sns_platform_endpoint.apns
     end

     options[:platform_application_arn] = platform_endpoint
     options[:token] = registration_id
     begin
       endpoint = sns.create_platform_endpoint(options)
     rescue AWS::SNS::Errors::InvalidParameter => e
       bad_request!(INVALID_PARAMETER,e.message)
     end
     
     endpoint[:endpoint_arn]
   end


   def batch_notification(target_arn,device,type,notification_type)
    message = get_message(type)
    sns = AWS::SNS::Client.new
     options = Hash.new



     options[:target_arn] = target_arn
     
    
      options[:message_structure] = "json"
      
      if notification_type == "apns"
        data =  {:aps =>{  :message => message,
                :mac => device.registration_id }}.to_json.to_s
        options[:message] =  {
                "APNS_SANDBOX" => data
                }.to_json
      elsif notification_type == "gcm"
        data = { :data => {  :message => message,
                :mac => device.registration_id }}.to_json.to_s 
        options[:message] =  {
                  "GCM" => data
                  }.to_json
      end          
                   
      begin
        response = sns.publish(options)
      rescue Exception => e 
      p "apns exception...................................." 
         p e
       end  

   end

   def send_batch_notification(user,device,type)
     target_arn_gcm = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint)
     target_arn_apns = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint)

      notification_threads = []
      target_arn_gcm.each do |target_arn|
        notification_threads << Thread.new {
        batch_notification(target_arn,device,type,"gcm")
      }
      end

      target_arn_apns.each do |target_arn|
        notification_threads << Thread.new {
        batch_notification(target_arn,device,type,"apns")
        }
      end 
   end 

   def send_notification(user,device)
    # get all the registration ids into one array
    # note the map(&) method call at the end
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
  
    status 200
    { :userid => device.user_id ,
      :gcm_devices => target_arn_gcm.count,
      :ios_devices => target_arn_apns.count
    }
   end 

   def batch_notification(user,message)
     target_arn_gcm = user.apps.select([:sns_endpoint,:notification_type]).where(notification_type: 1).map(&:sns_endpoint)
     target_arn_apns = user.apps.select([:sns_endpoint, :notification_type]).where(notification_type: 2).map(&:sns_endpoint)

      notification_threads = []
      target_arn_gcm.each do |target_arn|
       notification_threads << Thread.new {
        notify(target_arn,message,"gcm")
      }
      end

      target_arn_apns.each do |target_arn|
       notification_threads << Thread.new {
        notify(target_arn,message,"apns")
        }
      end 

   end 

   def notify(target_arn,message,notification_type)
     p "notification.."
     
     sns = AWS::SNS::Client.new
     options = Hash.new
     options[:target_arn] = target_arn
    data =  {  :message => message }.to_json

    options[:message_structure] = "json"
    if notification_type == "apns"
      data =  {:aps =>{  :message => message
              }}.to_json.to_s
      options[:message] =  {
              "APNS_SANDBOX" => data
              }.to_json
    elsif notification_type == "gcm"
      data = { :data => {  :message => message
             }}.to_json.to_s 
      options[:message] =  {
                "GCM" => data
                }.to_json
    end   

      begin
      response = sns.publish(options)
      rescue Exception => e 
        p "exception.........................."  
       p e
     end   
   end
  
   def get_message(type)
    message = ""
    case type
      when "deactivate" 
        message = Settings.deactivation_message
      when "upgrade"  
        message = Settings.upgrade_message
    end  
   end

   def upload_test_report_to_s3(file,model_no)
    s3 = AWS::S3.new  
     file_name = file.filename
     b = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_device_masters_path % [model_no] + '/' + file_name]
     b.write(file.tempfile)
  end

  def upload_capability_to_s3(file,firmware_prefix)
    s3 = AWS::S3.new  
     file_name = file.filename
     b = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_device_model_capabilities_path % [firmware_prefix] + '/'+ file_name]
     b.write(file.tempfile)
  end  

  def upload_type_capability_to_s3(file,type_code)
    s3 = AWS::S3.new  
     file_name = file.filename
     b = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_device_types_capabilities_path % [type_code] + '/' + file_name]
     b.write(file.tempfile)
  end 

  def get_playlist_data(device,event_data)
    s3 = AWS::S3.new
    data = []
    snap_url = nil
    snap = s3.buckets[Settings.s3_bucket_name].objects[Settings.s3_event_snap_path % [device.registration_id, event_data]] 
    
    snap_url = snap.url_for(:read, :secure => false).to_s

    data = get_playlist(device.registration_id,event_data,snap_url) 
    
    return data
  end 

  def get_alert_name(alert)
    if alert == 1
      "sound detected"
    elsif alert == 2
      "high temperature detected"  
    elsif alert == 3
      "low temperature detected"
    elsif alert == 4
      "motion detected"
    end      
  end

  def delete_objects(registration_ids,limit)
    s3 = AWS::S3.new
    semaphore = Mutex.new
    
    delete_events_threads = []
    data = []
    
     
    i = 0
          
    total = registration_ids.count
    registration_ids.each do |registration_id|
      i = i + 1
      print 13.chr
      print "%s of %s: current >> %s                                    " % [i.to_s, total.to_s, registration_id]
      if registration_id
        delete_events_threads << Thread.new {
          item = delete_events(registration_id,limit) 
          semaphore.synchronize {
            data << item if item
          } 
        }       
      end  # if 
    end # do
    delete_events_threads.each { |thr| thr.join } 
    Notifier.send_email(data,"Report for S3 folder clean-up").deliver if data.length > 0
  end 

    def delete_events(registration_id,limit)
      p limit
    s3 = AWS::S3.new
    #limit = 30
    clips_count = 0
    delete_events_count = 0
    begin
      snaps_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_snap_path % [registration_id,registration_id])
      sorted_list = snaps_collection.sort_by { |x| x.last_modified }  

      if sorted_list.length > limit
        delete_events_count = sorted_list.length - limit
        list_to_delete = sorted_list.first delete_events_count
        list_to_delete.each {|event| 
          event_key = event.key.split("snaps/")[1].split(".jpg")[0]         
          clips_collection = s3.buckets[Settings.s3_bucket_name].objects.with_prefix(Settings.s3_event_clip_path % [registration_id, event_key])
          clips_collection.each {|clip| 
            clips_count = clips_count + 1
            clip.delete
          }
          event.delete
        }
      end 


    rescue AWS::S3::Errors::NoSuchKey => e
      p "exception"
      p e.message
    end

    if delete_events_count > 0 || clips_count > 0 
      return {
        :registration_id => registration_id,
        :deleted_clips => clips_count,
        :deleted_snaps => delete_events_count
      }
    else 
      
    end   
    
  end 



  def get_limit(subscription_type)
    STORAGE_LIMIT[subscription_type]
  end

end

