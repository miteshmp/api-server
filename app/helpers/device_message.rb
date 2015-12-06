# Class Name :- DeviceMessage
# Description :- Contains "message" list


class DeviceMessage

	# Unknown Reason
	UNKNOWN = "unknown";

	# Message Separator
	MESSAGE_SEPATRATOR = "=";

	# Response to "get_upload_token" device service
	UPLOAD_TOKEN = "upload_token" ;

	# Failed response to any device service
	FAILED = "Failed" ;


	# Response to "clear_upload_token" device service
	CLEAR_UPLOAD_TOKEN = "Successfully reset upload token" ;

	RESET_UPLOAD_TOKEN = "Reset Upload Token" ;


	# Close Session Message
	UNABLE_TO_SEND_CLOSE_SESSION = "Unable to send RTMP close command";

	# Send HTTP status code 711
	SENT_DEVICE_UN_REGISTER_CODE = "Sent device unregister status code" ;


end