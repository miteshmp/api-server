class AlcatelSettings

	attr_accessor :push_notification_url,:device_register_url,:device_delete_url,:models,:sound_event,:motion_event,
	:supported_events,:server_session_timeout,:default_time_format

	
	def initialize
		@push_notification_url = "http://ipcam.phone-alert.alcatel-home.com/api/alarms/hubble_add.json?lang=en"
		@device_register_url = "http://ipcam.phone-alert.alcatel-home.com/api/sensors/hubble_add.json?lang=en"
		@device_delete_url = 'http://ipcam.phone-alert.alcatel-home.com/api/sensors/hubble_delete.json?lang=en'
		@models = ["0113"]
		@sound_event = 52
		@motion_event = 49
		@supported_events = [ EventType::SOUND_EVENT, EventType::MOTION_DETECT_EVENT ]
		@server_session_timeout = 30
		@default_time_format = "%Y-%m-%d\T%H:%M:%S%z"
	end	
	
end
