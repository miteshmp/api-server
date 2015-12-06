module DeviceCommandHelper

def send_command(cmd,device,key,value)
  
   Thread.new {

     ThreadUtility.with_connection do

      case cmd
        when CMD_ATTR_UPDATE
          command = Settings.camera_commands.extended_attribute_command % key
        when CMD_SET_REC_DESTINATION  
          command = Settings.camera_commands.set_recording_destination % value      
        else 
           # do nothing
      end  
    
       send_command_over_stun(device,command)
    
     end
   }
	
 end
end