# Class Name :- HubbleStreamMode
# Description :- HubbleStreamMode provides stream parameter details


class HubbleStreamMode

	RELAY_RTMP_STREAM_MODE = "relay_rtmp" ;

	# Stream URL which is used to get statictics information from Wowza Edge Server
	STREAM_INFO_URL = "http://%s:8080/streaminfo?application=%s&stream=%s" ;

	# Stream URL timeout
	STREAM_INFO_SERVER_TIMEOUT = 15 ;
	
end