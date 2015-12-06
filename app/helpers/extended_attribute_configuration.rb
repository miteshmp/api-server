# Class Name :- ExtendedAttributeConfiguration
# Description :- ExtendedAttributeConfiguration provides configuration parameter for entity which are supported 
#                by extended attribute framework

class ExtendedAttributeConfiguration


  	# Devise Entity
  	DEVICE_ENTITY = "Device" ;

  	# User Entity
  	USER_ENTITY = "User" ;

  	# DeviceModel Entity
  	DEVICE_MODEL_ENTITY = "DeviceModel" ;

  	# Extend Attribute Entity Supported by Hubble
  	ENTITY_SUPPORT = [ DEVICE_ENTITY ] ;

	NO_FILETER_PARAMETER = 5;

	INVALID_FILTER_SYNTAX_MESSAGE = "Invalid Filter Syntax" ;

	INVALID_FILTER_VALUE_MESSAGE = "Contains invalid value for filter parameters";

	FILTER_SEPARATOR = ':' ;

	FILTER_SEPARATOR_LENGTH = 1;

	FILTER_OPERATOR_SUPPORT = [ "=", "!=",">","<",">=","<="] ;


end