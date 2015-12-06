# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module DeviceEventHelper
  

  def collect_sorted_events(device_events,video_period)
    events = []
    event_data_list= Hash.new
    event_code_hash = Hash.new
    device_events.each do |event|
      begin 
        alert_name = get_alert_name(event.alert)
        Rails.logger.debug("1event_code_hash event len : #{event_code_hash.size}")
        if event.event_code.nil?
          event_code_hash[event.id[0]]={
          :id => event.id[0],
          :alert => event.alert,
          :value => event.value,
          :alert_name => alert_name,
          :time_stamp => event.event_time,
          :data => nil,
          :device_registration_id => event.device.registration_id,
          :has_motio_video => (video_period.to_i.days.ago..Time.now.utc).cover?(event.time_stamp)
        }
        else 
          event_code_hash[event.event_code]={
          :id => event.id[0],
          :alert => event.alert,
          :value => event.value,
          :alert_name => alert_name,
          :time_stamp => event.event_time,
          :data => nil,
          :device_registration_id => event.device.registration_id,
          :has_motio_video => (video_period.to_i.days.ago..Time.now.utc).cover?(event.time_stamp)
        }
        if (event.alert == EventType::MOTION_DETECT_EVENT)
          event_data_list[event.device.registration_id]= [] if event_data_list[event.device.registration_id].nil?
          event_data_list[event.device.registration_id] << event.event_code 
        end
        Rails.logger.debug("1event_data_list event len : #{event_data_list.size}")
        end
        
        
      rescue Exception => exception
        Rails.logger.warn("caught exception => #{exception}")
      ensure
      end
    end
    
    event_data_list.each { |reg_id,event_data_list|  
      #add thread for faster execution
      Rails.logger.info("reg_id :#{reg_id}  event_data_list : #{event_data_list.inspect}")
      if event_data_list.length > 0
      event_data_query_params={
        "registeration_id" => reg_id,
        "upload_api_token" => GeneralSettings.connect_settings[:upload_api_token],
        "event_data" => event_data_list
      }
      Rails.logger.debug("url : #{GeneralSettings.connect_settings[:upload_server_event_data_url]}params : #{event_data_query_params}")    
      upload_server_get_event_response=nil
#      begin
        upload_server_get_event_response=RestClient::Request.execute(:method => :post, :url => GeneralSettings.connect_settings[:upload_server_event_data_url],:payload => event_data_query_params,:timeout => nil,:open_timeout => nil,:headers => {'Content-Type' => 'application/json'})
#      rescue Exception => exception
#        Rails.logger.error("Error : #{exception.inspect}  #{exception.message}")
#      end
      if !upload_server_get_event_response.nil? && upload_server_get_event_response.code.eql?(200)
        begin
          response_json = JSON.parse(upload_server_get_event_response.body)
          response_json["data"]
          response_json["data"].each do |event|
            item=PlaylistItem.new
            Rails.logger.debug("event data : #{event['event_data']}") 
            item.image=event['image']
            item.file=event['file']
            item.title=""
            stored_data=event_code_hash[event['event_data']]
            stored_data[:data]=[] if stored_data[:data].nil?
            stored_data[:data] << item 
          end
        end
      else
        Rails.logger.error("Failure response code from upload server : #{upload_server_get_event_response.code}")
      end
    end
    }
    
      event_code_hash.each_value {|value| 
      Rails.logger.debug("motion:  #{value[:has_motio_video]}  data:  #{value[:data]} blank check: #{value[:data].blank?}")
      value[:data].each { |item|
           Rails.logger.debug("debug s")
           item.file = ""
         } if (!value[:has_motio_video]) && (!value[:data].blank?)  
       value.delete(:has_motio_video)
            events << value
          }
          
    
    events.sort_by { |k| k[:time_stamp] }
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
end
