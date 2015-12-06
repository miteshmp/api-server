require "./event_delete_config.rb"
require 'rest-client'
require 'json'
require 'open-uri'
require 'fileutils'
require 'cgi'






GET_DEVICE_QUERY="https://#{HOST_NAME}:#{PORT}/v1/devices.json?model_no=#{MODEL_NO}&api_key=#{API_KEY}"
TIME_FROM=CGI::escape(T_FROM)
TIME_TO=CGI::escape(T_TO)
DELETE_QUERY="https://#{HOST_NAME}:#{PORT}/v3/devices/%s/delete_events_session.json?"
DELETE_QUERY_ARGUMENTS="time_from=#{TIME_FROM}&time_to=#{TIME_TO}&api_key=#{API_KEY}"
puts "get_query: #{GET_DEVICE_QUERY}"


def http_client(method,url)
   puts "METHOD:  #{method}   \nURL :#{url}"
   RestClient::Request.execute(:method => method, :url => url,:timeout => nil,:open_timeout => nil)
end



get_response = http_client(:get,GET_DEVICE_QUERY)
if get_response.code.eql?(200)
  begin
    get_response_json = JSON.parse(get_response.body)
        puts "json data: #{get_response_json}"
    get_response_json["data"].each do |device|  
      
      delete_response=http_client(:delete,DELETE_QUERY % device["registration_id"]+DELETE_QUERY_ARGUMENTS)
      if delete_response.code.eql?(200)
        begin
          response_json = JSON.parse(delete_response.body)
          puts "Response : #{response_json}"
          response_json["data"].each do |event|
            if event['alert'].eql?(4) #motion trigger alert is 4
	      event_code=event['event_code'].split('.')[0]
              clips_to_be_deleted="#{CLIPS_PATH % device['registration_id']}#{event_code}*"
              snaps_to_be_deleted="#{SNAPS_PATH % device['registration_id']}#{event_code}*"
              puts "clips_to_be_deleted= #{clips_to_be_deleted}"
              puts "snaps_to_be_deleted= #{snaps_to_be_deleted}"
              FileUtils.rm(Dir.glob(clips_to_be_deleted))
              FileUtils.rm(Dir.glob(snaps_to_be_deleted))
              puts "motion file deleted"
            end
          end
        rescue => e
          puts "caught exception #{e}!"
        end  
      else
        puts "Bad responde from server :#{response.code}"
      end
    end
  rescue => e
    puts "caught exception #{e}!"
  end
end




