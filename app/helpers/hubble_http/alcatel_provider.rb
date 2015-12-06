 # Name :- HubbleHttp::AlcatelProvider

# module :- HubbleHttp
module HubbleHttp

	# class name :- AlcatelProvider
	class AlcatelProvider
		# include http method module
		include HTTParty
 
  		# http session time out
  		default_timeout GeneralSettings.alcatel_config.server_session_timeout

      #  ext_id :- Device Registration ID

      # User register
      def user_register(data)

      end 

      # User update
      def user_update(data)
      end

      # User delete
      def user_delete(data)
      end

      # Device register
      # At present device register in Alcatel server is done by app
      def device_register_url(data)
        # device_register not used at present since the app calls device register in Alcatel server directly.
        options =   { :body =>  {  :extid => data[:device].registration_id, :pss_id => data[:pss_id] } } 
        # Todo : Need to pass alcatel box id as pss_id 
        http_post(GeneralSettings.alcatel_config.device_register_url,options)      
      end 

      # Device update
      def device_update(data)
      end 

      # Device delete
      def device_delete(data)
        options =   { :body =>  {  :extid => data[:device].registration_id} }
        http_post(GeneralSettings.alcatel_config.device_delete_url,options)     
      end

		# Method :- send_push_notification
    # Description :- It will send message to third party server & return response
    
		def send_push_notification(data)
      # event_type : alcatel server alert type
      #  event_code :- Event value. For motion, it is event value to identify clips
      #  event_time :- Event time when it is generated.

      device = data[:device]
      alert_type = data[:parameters][:alert].to_i
      event_type = get_alcatel_server_notification_type(alert_type)
      event_time = Time.now.utc.to_s(GeneralSettings.alcatel_config.default_time_format)
      event_value = data[:parameters][:val]
      event_code = event_value ? event_value : EventType::NOT_AVAILABLE

      if GeneralSettings.alcatel_config.supported_events.include? alert_type
        options =   { :body =>  {  :extid => device.registration_id , :type => event_type,
                        :event_time => event_time, :event_code => event_code } }
                        
        http_post(GeneralSettings.alcatel_config.push_notification_url,options)
      end                  
		end

    def http_post(url,options)
      begin
        http_response = self.class.post(url, options)
        unless (http_response.code == HttpStatusCode::SUCCESS || http_response.body["status"] == "ok")
          NewRelic::Agent.notice_error("Alcatel Server error",                            
            :custom_params => {"DATA" => options, "ALCATEL URL" => url, "RESPONSE" => http_response })
        end
      rescue Exception => exception
        NewRelic::Agent.notice_error("Alcatel Provider exception",              
            :custom_params => {"DATA" => options, "ALCATEL URL" => url, "Exception" => exception })
      end
    end  

	end


end