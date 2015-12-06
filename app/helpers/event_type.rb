# Class Name :- EventType
# Description :- EventType provides event type number


class EventType


  PUSH_NOTIFICATION_TYPE_APNS = "apns";

  PUSH_NOTIFICATION_TYPE_GCM = "gcm";

  PUSH_NOTIFICATION_MESSAGE_STRUCTURE = "json" ;

  PUSH_NOTIFICATION_MESSAGE_TYPE_APNS = "APNS";

  PUSH_NOTIFICATION_MESSAGE_TYPE_APNS_SANDBOX = "APNS_SANDBOX";

  PUSH_NOTIFICATION_MESSAGE_TYPE_GCM = "GCM" ;

  NOT_AVAILABLE = "N/A" ;

  # Sound notification
  SOUND_EVENT = 1 ;

  SOUND_EVENT_MESSAGE = "Sound detected from ";

  # High temp notification
  HIGH_TEMP_EVENT = 2 ;

  HIGH_TEMP_EVENT_MESSAGE = "High temp from " ;

  # Low temo notification
  LOW_TEMP_EVENT = 3;

  LOW_TEMP_EVENT_MESSAGE = "Low temp from " ;

  # Motion Detect Event
  MOTION_DETECT_EVENT = 4;

  MOTION_DETECT_EVENT_MESSAGE = "Motion detected from " ;

  # Update Firmware Event
  UPDATING_FIRMWARE_EVENT = 5 ;

  UPDATING_FIRMWARE_EVENT_MESSAGE = "Updating firmware on ";

  # Sucess Firmware event
  SUCCESS_FIRMWARE_EVENT = 6;

  SUCCESS_FIRMWARE_EVENT_MESSAGE = "Firmware successfully updated on ";

  # Password changed
  RESET_PASSWORD_EVENT = 7;

  RESET_PASSWORD_EVENT_MESSAGE = "Reset password on %s platform";

  # Device removed from Account
  DEVICE_REMOVED_EVENT = 8;

  DEVICE_REMOVED_EVENT_MESSAGE = "Removed %s device from account";

  # Device added into account
  DEVICE_ADDED_EVENT = 9;

  DEVICE_ADDED_EVENT_MESSAGE = " Added %s device in account";

  # Change device temperature event
  CHANGE_TEMPERATURE_EVENT = 11 ;

  TEMPERATURE_SPLIT_SPECIFIER = "-" ;

  LENGTH_TEMPERATURE_INFO = 3; # 'old_temperature'-'current_temperature'-'minutes' ;

  CHANGE_TEMPERATURE_EVENT_MESSAGE = "Change temperature from %s to %s in %s minutes for %s" ;

  DEFAULT_CHANGE_TEMPERATURE_EVENT_MESSAGE = "Temperature is changed for %s" ;

  # Custom Event Notification
  CUSTOM_MESSAGE_EVENT = 999999 ;

  INFO_MESSAGE = 0

  FREE_TRIAL_EXPIRED = "free trial expired"
  FREE_TRIAL_EXPIRY_PENDING = "free trial expiry pending"
  FREE_TRIAL_APPLIED = "free trial applied"
  FREE_TRIAL_AVAILABLE = "free trial available"
  SUBSCRIPTION_CANCELED = "subscription cancelled"
  SUBSCRIPTION_APPLIED = "subscription applied"



  # From apple documentation :-
  # If the sound file doesn’t exist or default is specified as the value, the default alert sound is played.
  DEFAULT_SOUND_KEY_IOS_NOTIFICATION = "default";

  # Door Motion Detect Event
  DOOR_MOTION_DETECT_EVENT = 21;

  DOOR_MOTION_DETECT_EVENT_MESSAGE = "Motion detected at %s on %s" ;

  # Presence Detect Event
  PRESENCE_DETECT_EVENT = 22;

  PRESENCE_DETECT_EVENT_MESSAGE = "Presence detected at %s on %s" ;

  SENSOR_PAIRED_EVENT = 23;

  SENSOR_PAIRED_FAIL_EVENT = 24;

  SENSOR_PAIRED_EVENT_MESSAGE = "Sensor %s successfully paired with camera";

  SENSOR_PAIRED_FAIL_EVENT_MESSAGE =  "Failed to pair sensor %s with camera";
  
end