# Class Name :- HubbleIssueNotification
# Description :- This file defines configuration parameter for Hubble issue

class HubbleIssueNotification

	HUBBLE_DEVICE_ISSUE_SUBJECT = "[Hubble Device Notification] from ".concat(Rails.env).concat(" Environment") ;

	DEVICE_CLOSE_SESSION_ID = 1 ;

	DEVICE_CLOSE_SESSION_TYPE = "close_session" ;

	DEVICE_CLOSE_SESSION_REASON = "unable_to_send_RTMP_close_command" ;

	DEVICE_DE_REGISTER_SENT_MESSAGE_ID = 2;

	DEVICE_DE_REGISTER_SENT_MESSAGE_TYPE = "sent_device_deregistration_code" ;

	DEVICE_DE_REGISTER_SENT_MESSAGE_REASON = "device_deleted" ;
end