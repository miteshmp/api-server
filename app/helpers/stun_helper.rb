require 'time_difference'
module StunHelper

  
  def send_command_over_stun(device, command)
    mac_address = device.mac_address
    auth_token = device.auth_token
    
    encoded_command, iv = encode_command(command,auth_token)
    
    channel_id = Settings.channel_id
    uri = Settings.send_command_url %  [Settings.urls.portal_agent, mac_address, channel_id, encoded_command] 
    
    body = nil
    response = nil
    response_code = nil
    begin
      Timeout::timeout(Settings.time_out.portal_agent_timeout) do 
        response = HTTParty.post(uri,:headers => { 'Content-Type' => 'application/json' })
        response_code = response["deviceResponseCode"]
        if response_code == 200
          decoded_response = Base64.decode64(URI::decode(response["deviceResponseMsg"]))
          iv, encrypted_response = decoded_response.slice!(0...Settings.iv_length), decoded_response
          p "iv from decoded response: "+iv.to_hex_string
          p "encrypted_response: "+encrypted_response.to_hex_string
          body = aes128_decrypt(encrypted_response,auth_token,iv)
          p "body:"+body.to_hex_string
        else  
         body = Base64.decode64(URI::decode(response["deviceResponseMsg"]))
        end  
      end
    rescue Timeout::Error
      body = "Timeout error happened when connecting to PortalAgent"
    rescue Errno::ETIMEDOUT
      body = "Timeout error happened when connecting to PortalAgent"
    rescue Errno::ECONNREFUSED => e      
      internal_error!(CONNECTION_REFUSED, "Connection refused by PortalAgent server.")
    rescue OpenSSL::Cipher::CipherError
      body = Settings.cipher_decryption_exception
    rescue NoMethodError => e
      body = response
    rescue ArgumentError
      body = nil
    ensure
       #  if API Server is not able to send stun command to Device or any exception is occured, then 
       #  it is required that command should store in pending list. Once, Device is available, then
       #  Server will send command to Device.
       if response_code != 200       
         Thread.new{
              store_pending_commands(device,command,response["deviceResponseCode"])
              ActiveRecord::Base.connection.close
            } 
        end    
    end   

    
    {
      :device_response => {
        :device_id => device.id,
        :registration_id => device.registration_id,
        :mode => device.mode,
        :command => command,
        :body => body,
        :device_response_code => response_code
      }
    }
  end

  def is_device_available(device)
    
    mac_address = device.mac_address
    registration_id = device.registration_id
    command = "streamer_status"
    auth_token = device.auth_token
    
    encoded_command, iv = encode_command(command,auth_token)
    channel_id = Settings.channel_id # hard coded value - similar to BMS implementation      
    
    uri = Settings.send_command_url %  [Settings.urls.portal_agent, mac_address, channel_id, encoded_command]
   p uri
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
    end    

    status 200
    
    {
      :registration_id => registration_id,
      :is_available => available,
      :details => body
    }   
  end  

  def  get_ip_address
    env["HTTP_X_FORWARDED_FOR"] ||= env['REMOTE_ADDR']
  end

  def aes128_encrypt(key, data)
    data = add_padding(data,16)
    p "padded data: "+data
    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.encrypt
    cipher.key = key
    iv = cipher.random_iv
    cipher.padding = 0
    encrypted_command = cipher.update(data) + cipher.final

    {
      :iv => iv,
      :encrypted_command => encrypted_command
    }
  end 

  def add_padding(input_text,padding_multiple)
    while (input_text.length() % padding_multiple != 0)
      input_text += "\0"
    end  
    input_text
  end

  def aes128_decrypt(encrypted,key,iv)
    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = key
    decipher.iv = iv
    decipher.padding = 0
    plain = decipher.update(encrypted) + decipher.final
    plain = plain.gsub("\x00","")
  end

  def encode_command(command,auth_token)
    encrypted_data = aes128_encrypt(auth_token,command)
    iv = encrypted_data[:iv]
    encrypted_command = iv + encrypted_data[:encrypted_command]

    base_64_command = Base64.urlsafe_encode64(encrypted_command)

    encoded_command =  URI::encode(base_64_command)
    [encoded_command, iv]
  end  

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

  def store_pending_commands(device,command,status)
    parsed_command = Rack::Utils.parse_nested_query(command)
    command = parsed_command["command"] unless parsed_command["command"].nil?
    if CRITICAL_COMMANDS.include? command # check if the command is critical 
      critical_command = device.device_critical_commands.where(command: command).first
      critical_command = device.device_critical_commands.new unless critical_command
      critical_command.command = command
      critical_command.status = status
      #TODO :- Think that if Save is failed,how to handle pending commands
      critical_command.save!
    end  
  end  

end
