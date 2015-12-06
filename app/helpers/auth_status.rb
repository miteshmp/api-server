# Class Name :- AuthStatus
# Description :- AuthStatus provides "enumarations" for device & auth status

# Code 1XX dedicated for Device Authenticaion
class AuthStatus

	# Unknown status
	UNKNOWN_STATUS = 100;

# Valid Code shoud start with 101 
	# Device is present in API server with correct auth token
  DEVICE_FOUND = 101 ;

  # user is present in API server
  USER_FOUND = 102;

# Invalid code should start with 121
	# Device is registered with current (logged) User
	DEVICE_NOT_FOUND  = 121;

	# Device authentication token is required.
	UPLOAD_TOKEN_REQUIRED = 122;

  # Device is not registered yet, but present in device master.
  INVALID_UPLOAD_TOKEN = 123;

  # Connection issue
  SERVER_CONNECTION_ERROR = 124;

  USER_NOT_FOUND = 125;

end