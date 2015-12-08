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

ActiveRecord::Schema.define(:version => 20140206071004) do

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
  end

  add_index "apps", ["device_code"], :name => "index_apps_on_device_code", :unique => true

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

  create_table "device_critical_commands", :force => true do |t|
    t.text     "command"
    t.string   "status"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "device_events", :force => true do |t|
    t.integer  "alert"
    t.datetime "time_stamp"
    t.text     "data"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "value"
    t.text     "event_code"
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
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
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
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.string   "mac_address"
    t.integer  "device_master_batch_id"
    t.string   "hardware_version"
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

  create_table "device_settings", :force => true do |t|
    t.string   "key"
    t.string   "value"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "device_settings", ["device_id", "key"], :name => "index_device_settings_on_device_id_and_key", :unique => true

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
    t.string   "plan_id",                :default => "freemium"
    t.datetime "plan_changed_at"
    t.integer  "device_model_id"
    t.integer  "user_id"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.datetime "last_accessed_date"
    t.boolean  "deactivate",             :default => false
    t.datetime "target_deactivate_date"
    t.integer  "mode",                   :default => 1
    t.string   "firmware_version",       :default => "1"
    t.integer  "relay_usage",            :default => 0
    t.integer  "stun_usage",             :default => 0
    t.integer  "upnp_usage",             :default => 0
    t.boolean  "high_relay_usage",       :default => false
    t.integer  "relay_count",            :default => 0
    t.integer  "stun_count",             :default => 0
    t.integer  "upnp_count",             :default => 0
    t.datetime "relay_usage_reset_date"
    t.float    "latest_relay_usage",     :default => 0.0
    t.datetime "deleted_at"
    t.string   "auth_token"
    t.string   "mac_address"
  end

  add_index "devices", ["device_model_id"], :name => "index_devices_on_device_model_id"
  add_index "devices", ["mac_address"], :name => "index_devices_on_mac_address", :unique => true
  add_index "devices", ["registration_id"], :name => "index_devices_on_registration_id", :unique => true

  create_table "plan_parameters", :force => true do |t|
    t.string   "parameter"
    t.text     "value"
    t.integer  "subscription_plan_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "plan_parameters", ["subscription_plan_id", "parameter"], :name => "index_plan_parameters_on_subscription_plan_id_and_parameter", :unique => true

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
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "subscription_plans", ["plan_id"], :name => "index_subscription_plans_on_plan_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "type"
    t.date     "birthday"
    t.string   "name",                   :default => "", :null => false
    t.integer  "roles_mask",             :default => 2
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.datetime "deleted_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["name"], :name => "index_users_on_name", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
