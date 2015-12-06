CRITICAL_COMMANDS = ["set_plan_id","some_other_command","set_subscription","reset_factory","attribute_updated","add_ble_tag","remove_ble_tag"]
STORAGE_LIMIT = {"inactive" => 0,"freemium" => 1, "tier1" => 6, "tier2" => 12, "tier3" => 15}
ROLES = %w[admin user factory_user helpdesk_agent tester bp_server wowza_user talk_back_user upload_server marketing_admin]
EXTENDED_ATTRIBUTE_TO_DEVICE = ["recording_schedule","data_dump"]
EXTENDED_ATTRIBUTE_TO_APP = []
PLAN_PARAMETER_DATA_RETENTION_FIELD = "data_retention_days"
PLAN_PARAMETER_MAX_DEVICES_FIELD = "max_devices"
FREE_TRIAL_STATUS_ACTIVE = "active"
FREE_TRIAL_STATUS_EXPIRED = "expired"
RECURLY_SUBSCRIPTION_STATE_ACTIVE = "active"
RECURLY_SUBSCRIPTION_STATE_CANCELED = "canceled"
RECURLY_SUBSCRIPTION_STATE_EXPIRED = "expired"
RECURLY_SUBSCRIPTION_STATE_PENDING = "pending"
RECURLY_SUBSCRIPTION_STATE_FUTURE = "future"
RECURLY_ACCOUNT_CLOSED = "closed"
EXTENDED_ATTRIBUTE_TO_EXCLUDE = ["action","command","auth_token","route_info"]
PLATFORM_ENDPOINTS = {
    "default_gcm" => [Settings.sns_platform_endpoint.default_gcm_endpoint],
    "default_apns" => [Settings.sns_platform_endpoint.default_apns_endpoint,Settings.sns_platform_endpoint.default_testflight_apns],
    "hubble_gcm" => [Settings.sns_platform_endpoint.hubble_gcm_endpoint],
    "hubble_apns" => [Settings.sns_platform_endpoint.hubble_apns_endpoint,Settings.sns_platform_endpoint.hubble_testflight_apns_endpoint],
    "vtech_gcm" => [Settings.sns_platform_endpoint.vtech_gcm_endpoint],
    "vtech_apns" => [Settings.sns_platform_endpoint.vtech_apns_endpoint,Settings.sns_platform_endpoint.vtech_testflight_apns_endpoint],
    "adhoc_apns" => [Settings.sns_platform_endpoint.adhoc_apns_endpoint],
    "bork_gcm" => [Settings.sns_platform_endpoint.bork_gcm_endpoint],
    "bork_apns" => [Settings.sns_platform_endpoint.bork_apns_endpoint,Settings.sns_platform_endpoint.bork_testflight_apns_endpoint],
    "alcatel_gcm" => [Settings.sns_platform_endpoint.alcatel_gcm_endpoint],
    "alcatel_apns" => [Settings.sns_platform_endpoint.alcatel_apns_endpoint,Settings.sns_platform_endpoint.alcatel_testflight_apns_endpoint],
    "beurer_gcm" => [Settings.sns_platform_endpoint.beurer_gcm_endpoint],
    "beurer_apns" => [Settings.sns_platform_endpoint.beurer_apns_endpoint,Settings.sns_platform_endpoint.beurer_testflight_apns_endpoint]
}
DEFAULT_APP_UNIQUE_ID = { "gcm" => "default_gcm","apns" => "default_apns"}

MODEL_SUPPORTED_APPS = {
	"0836" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0066" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0096" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0083" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0036" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0076" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0085" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0073" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0086" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0854" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0662" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"1854" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0921" => {:gcm => ["vtech_gcm"],:apns => ["vtech_apns"]},
	"0931" => {:gcm => ["vtech_gcm"],:apns => ["vtech_apns"]},
	"0113" => {:gcm => ["alcatel_gcm"],:apns => ["alcatel_apns"]},
	"0112" => {:gcm => ["beurer_gcm"],:apns => ["beurer_apns"]},
	"0204" => {:gcm => ["beurer_gcm"],:apns => ["beurer_apns"]},
	"0001" => {:gcm => ["bork_gcm"],:apns => ["bork_apns"]},
	"0002" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]},
	"0003" => {:gcm => ["default_gcm","hubble_gcm"],:apns => ["default_apns","hubble_apns","adhoc_apns"]}
}
SUBSCRIPTION_SUPPORTED_APPS = {
	"gcm" => ["hubble_gcm"],
	"apns" => ["hubble_apns"]
}

CMD_ATTR_UPDATE="attribute_updated"
CMD_SET_REC_DESTINATION="set_recording_destination"

INVALID_STREAM_ID="Stream id is not 12 characters"
LIVE_STREAMING_IN_PROGRESS="Live streaming is in progress"
INVALID_CLIP="Clip does not exist"
INVALID_MD5SUM="Invalid MD5sum"
SD_NOT_INSERTED="SD card is not inserted"