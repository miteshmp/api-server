# Class Name :- HubbleConfiguration
# Description :- HubbleConfiguration provides configuration parameter for Device & User


class HubbleConfiguration

  # Device Upload token length
  DEVICE_UPLOAD_TOKEN_LENGTH = 12 ; # Actual length is 16 character

  # Expire Time for Upload Token
  DEVICE_UPLOAD_TOKEN_EXPIRE_TIME_SECONDS = (12 * 60 * 60) ;  # 12 Hours

  USER_UPLOAD_TOKEN_MIN_EXPIRE_TIME_SECONDS = ( 2 * 60 * 60);

  # expire time for registration details
  REGISTRATION_DETAILS_EXPIRE_TIME_SECONDS = ( 5 * 60); # 5 Minutes

  REGISTRATION_DETAIL_ID_LENGTH = 6 ;

  # New Server version
  NEW_SERVER_VERSION = "01.13.00" ;

  # Improvide security for Upload server
  UPLOAD_SERVER_VERSION = "01.14.00" ;

  # 0073 :- Device Model Security compromise
  UPLOAD_SERVER_VERSION_0073 = "01.15.16"

  # Event Time Feature
  EVENT_TIME_FEATURE_VERSION = "01.13.48" ;

  # Default Region code
  DEFAULT_REGION_CODE = 1;

  # This field is used to set close session retry number
  CLOSE_SESSION_RETRY = 3;

  # Derived Base Key
  DERIVED_KEY_BASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789abcdefghijklmnopqrstuvwxyz" ;

  # Stream name Length
  STREAM_NAME_LENGTH = 6 ; # hex ==> string of len 2*n is generated
                           #if url_safe_base64 is used ==> ( 4 / 3) * 9 = 12 character length

end