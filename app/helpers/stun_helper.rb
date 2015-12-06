require 'time_difference'

module StunHelper


  # Module :- send_command_over_stun
  # Description :- API server should send command to Device.

  def send_command_over_stun(device, command)

    mac_address = device.mac_address ;
    auth_token = device.auth_token ;

    # Get encrypted command using device authentication token
    encoded_command, iv = encode_command(command,auth_token) ;

    channel_id = Settings.channel_id ;
    uri = Settings.send_command_url %  [Settings.urls.portal_agent, mac_address, channel_id, encoded_command]  ;

    body = nil ;
    response = nil ;
    response_code = nil ;

    begin

      Timeout::timeout(Settings.time_out.portal_agent_timeout) do

        # Post command to PortalAgent server
        response = HTTParty.post(uri,:headers => { 'Content-Type' => 'application/json' })

        response_code = response["deviceResponseCode"] ;

        if response_code == 200

          decoded_response = Base64.decode64(URI::decode(response["deviceResponseMsg"]))
          iv, encrypted_response = decoded_response.slice!(0...Settings.iv_length), decoded_response

          # p "iv from decoded response: " + iv.to_hex_string
          # p "encrypted_response : " + encrypted_response.to_hex_string

          body = aes128_decrypt(encrypted_response,auth_token,iv)

          # p "body :- " + body.to_hex_string

        else

         body = Base64.decode64(URI::decode(response["deviceResponseMsg"]))

        end

      end

    rescue Timeout::Error
      body = "Timeout error happened when connecting to PortalAgent" ;

    rescue Errno::ETIMEDOUT
      body = "Timeout error happened when connecting to PortalAgent" ;

    rescue Errno::ECONNREFUSED => e
      internal_error!(CONNECTION_REFUSED, "Connection refused by PortalAgent server.") ;

    rescue OpenSSL::Cipher::CipherError
      body = Settings.cipher_decryption_exception ;

    rescue NoMethodError => e
      body = response ;

    rescue ArgumentError
      body = nil

    rescue SocketError => e
      body = e.message

    ensure

      #  if API Server is not able to send stun command to Device or any exception is occured, then 
      #  it is required that command should store in pending list. Once, Device is available, then
      #  Server will send command to Device.
      if response_code != 200

        Thread.new {

            begin
              store_pending_commands(device,command,response["deviceResponseCode"]) ;
              rescue Exception => exception
              ensure
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;
            end
        }

      end

    end   # End of Begin

    # Return response message to function
    {
      :device_response => {

        :device_id => device.id,
        :registration_id => device.registration_id,
        :command => command,
        :body => body,
        :device_response_code => response_code

      }
    }

  end
  # Complete module :- send_command_over_stun


  def is_device_available(device)
    
    mac_address = device.mac_address
    registration_id = device.registration_id
    command = "streamer_status"
    auth_token = device.auth_token
    
    encoded_command, iv = encode_command(command,auth_token)
    channel_id = Settings.channel_id # hard coded value - similar to BMS implementation      
    
    uri = Settings.send_command_url %  [Settings.urls.portal_agent, mac_address, channel_id, encoded_command]
 
    decoded_response = nil
    available = false
    body = nil
    begin
      Timeout::timeout(Settings.time_out.device_available_timeout) do 
        response = HTTParty.post(uri,:headers => { 'Content-Type' => 'application/json' })
        if response["deviceResponseCode"] == 200

          decoded_response = Base64.decode64(URI::decode(response["deviceResponseMsg"]))
          iv, encrypted_response = decoded_response.slice!(0...Settings.iv_length), decoded_response
          p "iv from decoded response: "+iv
          p "encrypted_response: "+encrypted_response
          body = aes128_decrypt(encrypted_response,auth_token,iv)
          available = "available".casecmp(body.to_s) == 0 ? true : false  unless (body.nil? || body.empty?)
        else 
          body = Base64.decode64(URI::decode(response["deviceResponseMsg"]))
          available = false
        end   
       
      end  
    rescue Timeout::Error
      available = false
    rescue Errno::ETIMEDOUT
      available = false
    rescue Errno::ECONNREFUSED => e      
       available = false
    rescue OpenSSL::Cipher::CipherError
       available = false
    rescue NoMethodError => e
      available = false 
    rescue ArgumentError
      available = false
    rescue SocketError => e
      available = false   
    end    

    status 200
    
    {
      :registration_id => registration_id,
      :is_available => available,
      :details => body
    }   
  end  

  # Module :- get_ip_address
  # Description :- Return remote IP addresss
  def  get_ip_address
     ip = env["x-forwarded-for"] || env["X-FORWARDED-FOR"] || env["X-Forwarded-For"] || env["http_x_forwarded_for"]|| env["HTTP_X_FORWARDED_FOR"] || env["Http_X_Forwarded_For"] || env['remote_addr'] || env['REMOTE_ADDR'] || env['Remote_Addr']  || env["proxy-client-ip"] || env["PROXY-CLIENT-IP"] || env["Proxy-Client-IP"] || ENV["wl-proxy-client-ip"] || env["WL-PROXY-CLIENT-IP"] || ENV["WL-Proxy-Client-IP"] || env["http_client_ip"] || env["HTTP_CLIENT_IP"] || env["Http_Client_Ip"]
	   ip.split(',')[0]			
  end
  # Complete :- get_ip_address

  # Module :- get_wowza_rtmp_address
  # Description :- Return least loaded wowza RTMP URL.
  
  def  get_wowza_rtmp_address(*args)

    loadbalancer_uri = nil;
    rtmp_ip = nil ;
    
    #method overloading 
    region_code=args[0]
    model_no=GeneralSettings.binatone_model
    puts "before block#{model_no}"
    if(args.size==2)
      model_no=args[1]
      puts "in 2 arg block#{model_no}" 
    end

    case model_no
       #for connect camera
    when *GeneralSettings.connect_settings[:model]
      http_url = "http://" + GeneralSettings.connect_settings[:rtmp_loadbalancer_ip]
      loadbalancer_uri = Settings.load_balancer_url % [http_url,GeneralSettings.connect_settings[:rtmp_loadbalancer_port],region_code];
      Rails.logger.debug "connect rtmp block"
    else #for normal hubble cameras old 
      # Get Wowza Load Balancer
      if(Settings.urls.wowza_server[0..3].upcase == "HTTP")
        loadbalancer_uri = Settings.load_balancer_url % [Settings.urls.wowza_server,Settings.urls.wowza_http_port,region_code] ;
      else
        http_url = "http://" + Settings.urls.wowza_server
        loadbalancer_uri = Settings.load_balancer_url % [http_url,Settings.urls.wowza_http_port,region_code] ;
      end
      Rails.logger.debug "hubble rtmp block"
    end
    Rails.logger.debug "Model no: #{model_no}  RTMP REQUEST URL: #{loadbalancer_uri}"
    
    begin

      Timeout::timeout(Settings.time_out.wowza_server_timeout) do

        response =  HTTParty.get(loadbalancer_uri)
        rtmp_ip  =  response.split('=').last

      end

      rescue Timeout::Error
        Rails.logger.error("Timeout occured in connecting wowza load balancer server");

      rescue Errno::ETIMEDOUT
        Rails.logger.error("HTTP Timeout occured  in connecting wowza load balancer server ");

      rescue Errno::ECONNREFUSED => exception
        Rails.logger.error("get_wowza_rtmp_address :-  #{exception.message}");

      rescue SocketError => exception
        Rails.logger.error("get_wowza_rtmp_address :-  #{exception.message}");
    end

    return rtmp_ip
  end
  # Complete :- "get_wowza_rtmp_address"

  # Module :- get_wowza_stream_stat
  # Description :- Return Stream statistics
  def  get_wowza_stream_stat(relay_rtmp_ip,applicationName,streamName)

    relayRtmpURL = HubbleStreamMode::STREAM_INFO_URL % [relay_rtmp_ip, applicationName, streamName] ;
    stream_stat_info = nil ;

    begin

      Timeout::timeout( HubbleStreamMode::STREAM_INFO_SERVER_TIMEOUT ) do

        stream_stat_info =  HTTParty.get(relayRtmpURL)

      end

      rescue Timeout::Error
        Rails.logger.error("Timeout occured in connecting wowza edge server");

      rescue Errno::ETIMEDOUT
        Rails.logger.error("HTTP Timeout occured  in connecting wowza edge server ");

      rescue Errno::ECONNREFUSED => exception
        Rails.logger.error("get_wowza_stream_stat :-  #{exception.message}");

      rescue SocketError => exception
        Rails.logger.error("get_wowza_stream_stat :-  #{exception.message}");
    end

    return stream_stat_info
  end
  # Complete :- "get_wowza_stream_stat"


  # Module :- get_user_agent
  # Description :- Return User Agent
  def get_user_agent
    # Get User Agent Using Env variable
    user_agent = UserAgent.parse ( env["HTTP_USER_AGENT"] );
    return user_agent.browser ;
  end

  # Module :- aes128_encrypt
  # Description :- Apply AES 128 algorithm on data
  def aes128_encrypt(key, data)

    data = add_padding(data,16) ;

    cipher = OpenSSL::Cipher::AES.new(128, :CBC) ;
    cipher.encrypt ;
    cipher.key = key ;
    iv = cipher.random_iv ;
    cipher.padding = 0 ;

    # Final encrypt data
    encrypted_command = cipher.update(data) + cipher.final ;

    # Return iv & encrypted data in array.
    {
      :iv => iv,
      :encrypted_command => encrypted_command
    }

  end
  # Complete module :- aes128_encrypt

  # Module :- add_padding
  # Description :- Add padding character based on padding_multiple length

  def add_padding(input_text,padding_multiple)

    while (input_text.length() % padding_multiple != 0)
      input_text += "\0"
    end
    input_text

  end
  # Complete module :- add_padding

  # Module :- aes128_decrypt
  # Description :- Decrypt data using Key & IV

  def aes128_decrypt(encrypted,key,iv)

    decipher = OpenSSL::Cipher::AES.new(128, :CBC) ;
    decipher.decrypt ;
    decipher.key = key ;
    decipher.iv = iv ;
    decipher.padding = 0 ;

    # decrypt data
    plain = decipher.update(encrypted) + decipher.final ;

    plain = plain.gsub("\x00","") ;

  end
  # Complete module :- aes128_decrypt

  # Module :- encode_command
  # Description :- Apply AES encryption on command using auth_token
  def encode_command(command,auth_token)

    encrypted_data = aes128_encrypt(auth_token,command) ;

    # Get IV  & Encrpted data from array which is returned by "aes128_encrypt"
    iv = encrypted_data[:iv] ;
    encrypted_command = iv + encrypted_data[:encrypted_command] ;

    base_64_command = Base64.urlsafe_encode64(encrypted_command) ;

    encoded_command =  URI::encode(base_64_command) ;

    # return encoded data & IV
    [encoded_command, iv]

  end
  # Complete module :- encode_command


  # Module :- "is_device_available_cache_status"
  # Description :- Fetch device status from Stun Server, instead of getting from
  #               device directly.
  #               avoid timing issue.
  def is_device_available_cache_status(mac_address)

    begin
      status = false;
      Timeout::timeout(Settings.time_out.device_cache_available_timeout) do

        uri = Settings.get_cache_device_status %  [Settings.urls.portal_agent, mac_address] ;
      # print uri
        response = HTTParty.post(uri,:headers => { 'Content-Type' => 'application/json' })
        device_status = response["status"] if response["deviceResponseCode"] == 200 ;
      # print device_status
        status = ( device_status != nil && device_status.downcase.casecmp("available") ) ? true : false;

      end
      rescue Timeout::Error
      rescue Errno::ETIMEDOUT
      rescue Errno::ECONNREFUSED => exception
      rescue SocketError => exception
    end
    status
  end
  # Complete :- "is_device_available_cache_status"

  def get_remote_ip(mac_address)
    begin
      remote_ip = nil
      Timeout::timeout(Settings.time_out.portal_agent_timeout) do 
        uri = Settings.get_remote_ip_url %  [Settings.urls.portal_agent, mac_address]
        response = HTTParty.get(uri,:headers => { 'Content-Type' => 'application/json' })
        remote_ip = response["remoteIp"] if response["deviceResponseCode"] == 200
      end
    rescue Timeout::Error
    rescue Errno::ETIMEDOUT
    rescue Errno::ECONNREFUSED => e      
    end 
    remote_ip
  end  

  def store_pending_commands(device,query_string,status)
    parsed_command = Rack::Utils.parse_nested_query(query_string)
    command = parsed_command["command"] unless parsed_command["command"].nil?
    if CRITICAL_COMMANDS.include? command # check if the command is critical
      critical_command = nil ;
      if device.device_critical_commands
        critical_command = device.device_critical_commands.where(command: query_string).first
      end
      critical_command = device.device_critical_commands.new unless critical_command
      critical_command.command = query_string
      critical_command.status = status
      #TODO :- Think that if Save is failed,how to handle pending commands
      critical_command.save!
    end  
  end  

end
