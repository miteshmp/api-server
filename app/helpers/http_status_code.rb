# Class Name :- HttpStatusCode
# Description :- This file defines Hubble HTTP Status code.

# Code 7XX dedicated for  Hubble HTTP status code

class HttpStatusCode

	# http query status
	SUCCESS						= 200 ;

	# client error code
	PARAMETERS_INSUFFICIENT				= 400 ;
	CAMERA_NOT_REGISTERED_IN_PORTAL 	= 401 ;
	HTTP_CLIENT_CONFLICT_ERROR_CODE		= 409 ;

	# server error code
	INTERNAL_SERVER_ERROR		= 500 ;

end