# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150313080433) do

  create_table " device_events_1", :force => true do |t|
    t.integer  "alert"
    t.datetime "time_stamp"
    t.text     "data"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "value"
    t.text     "event_code"
    t.datetime "deleted_at"
    t.datetime "event_time"
  end

  add_index " device_events_1", ["alert"], :name => "index_ device_events_1_on_alert"
  add_index " device_events_1", ["deleted_at"], :name => "index_ device_events_1_on_deleted_at"
  add_index " device_events_1", ["device_id"], :name => "index_ device_events_1_on_device_id"
  add_index " device_events_1", ["event_code"], :name => "index_ device_events_1_on_event_code", :length => {"event_code"=>30}
  add_index " device_events_1", ["time_stamp"], :name => "index_ device_events_1_on_time_stamp"

  create_table "action_configs", :force => true do |t|
    t.string   "action_name"
    t.string   "action_value"
    t.string   "action_rule"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "device_model_id"
  end

  add_index "action_configs", ["device_model_id"], :name => "index_action_configs_on_device_model_id"

  create_table "api_call_issues", :force => true do |t|
    t.string   "api_type"
    t.string   "error_reason"
    t.string   "error_data"
    t.integer  "count",        :default => 0
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "api_call_issues", ["api_type", "error_reason", "error_data"], :name => "issue_index", :unique => true

  create_table "apps", :force => true do |t|
    t.string   "name"
    t.string   "device_code"
    t.string   "type"
    t.integer  "notification_type"
    t.string   "registration_id"
    t.string   "sns_endpoint"
    t.string   "software_version"
    t.integer  "user_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "app_unique_id"
  end

  add_index "apps", ["user_id"], :name => "index_apps_on_user_id"

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "authentications", :force => true do |t|
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.string   "uname"
    t.string   "uemail"
    t.string   "secret"
    t.string   "link"
    t.string   "name"
    t.string   "code"
    t.string   "access_token"
    t.string   "refresh_token"
    t.time     "access_token_expires_at"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "background_jobs", :force => true do |t|
    t.integer  "local_ip_address", :limit => 8
    t.integer  "total_job_time"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "device_app_notification_settings", :force => true do |t|
    t.integer  "app_id"
    t.integer  "device_id"
    t.integer  "alert"
    t.boolean  "is_enabled"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "device_app_notification_settings", ["app_id"], :name => "index_device_app_notification_settings_on_app_id"
  add_index "device_app_notification_settings", ["device_id"], :name => "index_device_app_notification_settings_on_device_id"

  create_table "device_capabilities", :force => true do |t|
    t.integer  "device_id"
    t.text     "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "device_capabilities", ["device_id"], :name => "index_device_capabilities_on_device_id"

  create_table "device_critical_commands", :force => true do |t|
    t.text     "command"
    t.string   "status"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "device_critical_commands", ["device_id"], :name => "index_device_critical_commands_on_device_id"

  create_table "device_events", :force => true do |t|
    t.integer  "alert"
    t.datetime "time_stamp"
    t.text     "data"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "value"
    t.text     "event_code"
    t.datetime "deleted_at"
    t.string   "event_time"
    t.datetime "eventtime2"
  end

  add_index "device_events", ["alert"], :name => "index_device_events_on_alert"
  add_index "device_events", ["deleted_at"], :name => "index_device_events_on_deleted_at"
  add_index "device_events", ["device_id"], :name => "index_device_events_on_device_id"
  add_index "device_events", ["event_code"], :name => "index_device_events_on_event_code", :length => {"event_code"=>30}
  add_index "device_events", ["time_stamp"], :name => "index_device_events_on_time_stamp"

  create_table "device_events_1", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "alert"
    t.datetime "time_stamp"
    t.text     "data"
    t.integer  "device_id",  :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "value"
    t.text     "event_code"
    t.datetime "deleted_at"
    t.datetime "event_time"
  end

  add_index "device_events_1", ["alert"], :name => "index_device_events_1_on_alert"
  add_index "device_events_1", ["deleted_at"], :name => "index_device_events_1_on_deleted_at"
  add_index "device_events_1", ["device_id"], :name => "index_device_events_1_on_device_id"
  add_index "device_events_1", ["event_code"], :name => "index_device_events_1_on_event_code", :length => {"event_code"=>30}
  add_index "device_events_1", ["event_time"], :name => "index_device_events_1_on_event_time"
  add_index "device_events_1", ["time_stamp"], :name => "index_device_events_1_on_time_stamp"

  create_table "device_free_trials", :force => true do |t|
    t.string   "device_registration_id"
    t.integer  "user_id"
    t.string   "plan_id"
    t.integer  "trial_period_days"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.string   "status"
  end

  create_table "device_invitations", :force => true do |t|
    t.integer  "shared_by"
    t.string   "shared_with"
    t.string   "invitation_key"
    t.integer  "reminder_count", :default => 0
    t.integer  "device_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "device_invitations", ["shared_by", "shared_with", "device_id"], :name => "invitation", :unique => true

  create_table "device_locations", :force => true do |t|
    t.string   "local_ip"
    t.integer  "local_port_1"
    t.integer  "local_port_2"
    t.integer  "local_port_3"
    t.integer  "local_port_4"
    t.string   "remote_ip"
    t.integer  "remote_port_1"
    t.integer  "remote_port_2"
    t.integer  "remote_port_3"
    t.integer  "remote_port_4"
    t.integer  "device_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.string   "remote_iso_code"
    t.integer  "remote_region_code", :default => 1
  end

  add_index "device_locations", ["device_id"], :name => "index_device_locations_on_device_id", :unique => true

  create_table "device_master_batches", :force => true do |t|
    t.string   "file_name"
    t.integer  "device_model_id"
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "device_masters", :force => true do |t|
    t.string   "registration_id"
    t.datetime "time"
    t.string   "firmware_version"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.string   "mac_address"
    t.integer  "device_master_batch_id"
    t.string   "hardware_version"
    t.string   "serial_number",          :default => "0"
  end

  add_index "device_masters", ["mac_address"], :name => "index_device_masters_on_mac_address", :unique => true
  add_index "device_masters", ["registration_id"], :name => "index_device_masters_on_registration_id", :unique => true

  create_table "device_model_capabilities", :force => true do |t|
    t.string   "firmware_prefix"
    t.text     "capability"
    t.integer  "device_model_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "device_model_capabilities", ["device_model_id", "firmware_prefix"], :name => "capability", :unique => true

  create_table "device_models", :force => true do |t|
    t.string   "model_no"
    t.string   "name"
    t.string   "description"
    t.integer  "device_type_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.datetime "deleted_at"
    t.integer  "udid_scheme",    :default => 1
  end

  add_index "device_models", ["device_type_id"], :name => "index_device_models_on_device_type_id"

  create_table "device_settings", :force => true do |t|
    t.string   "key"
    t.string   "value"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "device_settings", ["device_id", "key"], :name => "index_device_settings_on_device_id_and_key", :unique => true

  create_table "device_timezones", :primary_key => "device_id", :force => true do |t|
    t.string "timezone"
  end

  create_table "device_types", :force => true do |t|
    t.string   "type_code"
    t.string   "name"
    t.string   "description"
    t.text     "capability"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.datetime "deleted_at"
  end

  add_index "device_types", ["type_code"], :name => "index_device_types_on_type_code", :unique => true

  create_table "devices", :force => true do |t|
    t.string   "name"
    t.string   "registration_id"
    t.string   "access_token"
    t.float    "time_zone"
    t.string   "plan_id",                 :default => "freemium"
    t.datetime "plan_changed_at"
    t.integer  "device_model_id"
    t.integer  "user_id"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.datetime "last_accessed_date"
    t.boolean  "deactivate",              :default => false
    t.datetime "target_deactivate_date"
    t.integer  "mode",                    :default => 1
    t.string   "firmware_version",        :default => "1"
    t.integer  "relay_usage",             :default => 0
    t.integer  "stun_usage",              :default => 0
    t.integer  "upnp_usage",              :default => 0
    t.boolean  "high_relay_usage",        :default => false
    t.integer  "relay_count",             :default => 0
    t.integer  "stun_count",              :default => 0
    t.integer  "upnp_count",              :default => 0
    t.datetime "relay_usage_reset_date"
    t.float    "latest_relay_usage",      :default => 0.0
    t.datetime "deleted_at"
    t.string   "auth_token"
    t.string   "mac_address"
    t.integer  "firmware_status",         :default => 0
    t.datetime "firmware_time"
    t.string   "host_ssid"
    t.string   "host_router"
    t.string   "upload_token"
    t.string   "upload_token_expires_at"
    t.datetime "registration_at"
    t.string   "stream_name"
    t.string   "derived_key"
    t.string   "imsi_code"
    t.datetime "freetrial_notified_at"
  end

  add_index "devices", ["auth_token"], :name => "auth_token_UNIQUE", :unique => true
  add_index "devices", ["auth_token"], :name => "index_devices_on_auth_token", :unique => true
  add_index "devices", ["device_model_id"], :name => "index_devices_on_device_model_id"
  add_index "devices", ["freetrial_notified_at"], :name => "index_devices_on_freetrial_notified_at"
  add_index "devices", ["mac_address"], :name => "index_devices_on_mac_address", :unique => true
  add_index "devices", ["registration_id"], :name => "index_devices_on_registration_id", :unique => true
  add_index "devices", ["stream_name"], :name => "index_devices_on_stream_name"
  add_index "devices", ["user_id"], :name => "index_devices_on_user_id"

  create_table "event_logs", :force => true do |t|
    t.string   "event_name"
    t.string   "event_description"
    t.string   "remote_ip"
    t.string   "registration_id"
    t.string   "user_agent"
    t.datetime "time_stamp"
    t.integer  "user_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "event_logs", ["user_id"], :name => "index_event_logs_on_user_id"

  create_table "extended_attributes", :force => true do |t|
    t.string   "entity_type"
    t.integer  "entity_id"
    t.string   "key"
    t.text     "value"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "marketing_contents", :force => true do |t|
    t.string   "key"
    t.text     "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.time     "deleted_at"
  end

  create_table "plan_parameters", :force => true do |t|
    t.string   "parameter"
    t.text     "value"
    t.integer  "subscription_plan_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "plan_parameters", ["subscription_plan_id", "parameter"], :name => "index_plan_parameters_on_subscription_plan_id_and_parameter", :unique => true

  create_table "recipes", :force => true do |t|
    t.string   "name"
    t.integer  "program_code"
    t.string   "default_duration"
    t.string   "min_duration"
    t.string   "max_duration"
    t.integer  "device_model_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.datetime "deleted_at"
  end

  add_index "recipes", ["device_model_id"], :name => "index_recipes_on_device_model_id"
  add_index "recipes", ["name"], :name => "index_recipes_on_name"
  add_index "recipes", ["program_code"], :name => "index_recipes_on_program_code"

  create_table "registration_details", :force => true do |t|
    t.string   "registration_id"
    t.string   "mac_address"
    t.string   "local_ip"
    t.string   "net_mask"
    t.string   "gateway"
    t.string   "remote_ip"
    t.string   "expire_at"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "registration_details", ["mac_address"], :name => "index_registration_details_on_mac_address", :unique => true
  add_index "registration_details", ["registration_id"], :name => "index_registration_details_on_registration_id", :unique => true

  create_table "relay_sessions", :force => true do |t|
    t.string   "registration_id"
    t.string   "session_key"
    t.string   "stream_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "relay_sessions", ["registration_id"], :name => "index_relay_sessions_on_registration_id", :unique => true
  add_index "relay_sessions", ["session_key", "stream_id"], :name => "index_relay_sessions_on_session_key_and_stream_id", :unique => true

  create_table "sample2s", :force => true do |t|
    t.string   "name"
    t.datetime "timestamp"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sample_events", :force => true do |t|
    t.string   "alert"
    t.datetime "time_stamp"
    t.integer  "devices_id"
  end

  create_table "settings", :force => true do |t|
    t.string   "var",                      :null => false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", :limit => 30
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "settings", ["thing_type", "thing_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

  create_table "shared_devices", :force => true do |t|
    t.integer  "shared_by"
    t.integer  "shared_with"
    t.integer  "device_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "shared_devices", ["shared_by", "shared_with", "device_id"], :name => "shared_device", :unique => true

  create_table "subscription_plans", :force => true do |t|
    t.string   "plan_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "price_cents"
    t.string   "currency_unit"
    t.integer  "renewal_period_month"
  end

  add_index "subscription_plans", ["plan_id"], :name => "index_subscription_plans_on_plan_id", :unique => true

  create_table "time_zone_mappings", :id => false, :force => true do |t|
    t.float  "timezone_float"
    t.string "timezone"
  end

  create_table "user_subscriptions", :force => true do |t|
    t.integer  "user_id"
    t.string   "plan_id"
    t.string   "subscription_uuid"
    t.string   "subscription_source"
    t.datetime "deleted_at"
    t.integer  "subscription_plan_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "state"
    t.datetime "expires_at"
  end

  create_table "users", :force => true do |t|
    t.string   "type"
    t.date     "birthday"
    t.string   "name",                    :default => "", :null => false
    t.integer  "roles_mask",              :default => 2
    t.string   "email",                   :default => "", :null => false
    t.string   "encrypted_password",      :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",         :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.datetime "deleted_at"
    t.string   "upload_token"
    t.string   "upload_token_expires_at"
  end

  add_index "users", ["authentication_token"], :name => "authentication_token_UNIQUE", :unique => true
  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["name"], :name => "index_users_on_name", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
