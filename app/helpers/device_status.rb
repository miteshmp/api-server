# Class Name :- DeviceStatus
# Description :- DeviceStatus provides "enumarations" for device status

class DeviceStatus
	
	# Unknown status
	UNKNOWN_STATUS = 0 ;

	# Device is not present in device Master
	NOT_FOUND_IN_DEVICE_MASTER = 1 ;

  	# Device is not registered yet, but present in device master.
  	NOT_REGISTERED_DEVICE = 2 ;

	# Device is registered with current (logged) User
	REGISTERED_CURRENT_USER  = 3 ;

	# Device is registered with other User
	REGISTERED_OTHER_USER =  4 ;

	# Device is deleted from previous account & ready for registration
  	DELETED_DEVICE = 5 ;

end