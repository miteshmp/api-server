# Class Name :-  AlcatelHelper
# Description :- AlcatelConfiguration provides configuration parameter for Device & User


module AlcatelHelper

		# Method :- get_alcatel_server_notification_type
		# Description :- Return associated event type

    	def get_alcatel_server_notification_type(hubble_event_type)

      		alcatel_server_notification_type = -1;

      		case hubble_event_type

      			when EventType::SOUND_EVENT
      				alcatel_server_notification_type = GeneralSettings.alcatel_config.sound_event

      			when EventType::MOTION_DETECT_EVENT
      				alcatel_server_notification_type = GeneralSettings.alcatel_config.motion_event

      		end

      		return alcatel_server_notification_type
    	end
    	# completed :- "get_alcatel_server_notification_type"
end