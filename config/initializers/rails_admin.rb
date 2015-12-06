# # RailsAdmin config file. Generated on February 11, 2015 12:09
# # See github.com/sferik/rails_admin for more informations

# RailsAdmin.config do |config|


#   ################  Global configuration  ################

#   # Set the admin name here (optional second array element will appear in red). For example:
#   config.main_app_name = ['Api Server', 'Admin']
#   config.authenticate_with {}
# config.current_user_method {}
#   # config.authorize_with do
#   #   redirect_to main_app.new_admin_session_path unless current_admin
#   # end
#   # or for a more dynamic name:
#   # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

#   # RailsAdmin may need a way to know who the current user is]
#   # config.current_user_method { current_user } # auto-generated
  
#   config.actions do
#     # root actions
#     dashboard                     # mandatory
#     # collection actions 
#     index                         # mandatory
#     show
#     edit
#     delete
#   end

#   config.model 'Device' do
#     edit do
#       field :plan_id
#       field :freetrial_notified_at
#       field :plan_changed_at
#     end
#   end

#   # If you want to track changes on your models:
#   # config.audit_with :history, 'User'

#   # Or with a PaperTrail: (you need to install it first)
#   # config.audit_with :paper_trail, 'User'

#   # Display empty fields in show views:
#   # config.compact_show_view = false

#   # Number of default rows per-page:
#   config.default_items_per_page = 20

#   # Exclude specific models (keep the others):
#   # config.excluded_models = ['ActionConfig', 'ApiCallIssues', 'App', 'Authentication', 'BackgroundJob', 'Device', 'DeviceAppNotificationSetting', 'DeviceCapability', 'DeviceCriticalCommand', 'DeviceEvent', 'DeviceFreeTrial', 'DeviceInvitation', 'DeviceLocation', 'DeviceMaster', 'DeviceMasterBatch', 'DeviceModel', 'DeviceModelCapability', 'DeviceSetting', 'DeviceType', 'EventLog', 'ExtendedAttribute', 'MarketingContent', 'PlanParameter', 'Recipe', 'RegistrationDetail', 'RelaySession', 'SharedDevice', 'SubscriptionPlan', 'User', 'UserSubscription']

#   # Include specific models (exclude the others):
#   config.included_models = ['Device', 'DeviceFreeTrial', 'UserSubscription']

#   # Label methods for model instances:
#   # config.label_methods << :description # Default is [:name, :title]


#   ################  Model configuration  ################

#   # Each model configuration can alternatively:
#   #   - stay here in a `config.model 'ModelName' do ... end` block
#   #   - go in the model definition file in a `rails_admin do ... end` block

#   # This is your choice to make:
#   #   - This initializer is loaded once at startup (modifications will show up when restarting the application) but all RailsAdmin configuration would stay in one place.
#   #   - Models are reloaded at each request in development mode (when modified), which may smooth your RailsAdmin development workflow.


#   # Now you probably need to tour the wiki a bit: https://github.com/sferik/rails_admin/wiki
#   # Anyway, here is how RailsAdmin saw your application's models when you ran the initializer:



#   ###  ActionConfig  ###

#   # config.model 'ActionConfig' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your action_config.rb model definition

#   #   # Found associations:



#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :action_name, :string 
#   #     configure :action_value, :string 
#   #     configure :action_rule, :string 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :device_model_id, :integer 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  ApiCallIssues  ###

#   # config.model 'ApiCallIssues' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your api_call_issues.rb model definition

#   #   # Found associations:



#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :api_type, :string 
#   #     configure :error_reason, :string 
#   #     configure :error_data, :string 
#   #     configure :count, :integer 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  App  ###

#   # config.model 'App' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your app.rb model definition

#   #   # Found associations:

#   #     configure :user, :belongs_to_association 
#   #     configure :device_app_notification_settings, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :name, :string 
#   #     configure :device_code, :string 
#   #     configure :type, :string 
#   #     configure :notification_type, :enum 
#   #     configure :registration_id, :string 
#   #     configure :sns_endpoint, :string 
#   #     configure :software_version, :string 
#   #     configure :user_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  Authentication  ###

#   # config.model 'Authentication' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your authentication.rb model definition

#   #   # Found associations:

#   #     configure :user, :polymorphic_association         # Hidden 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :resource_id, :integer 
#   #     configure :resource_type, :string 
#   #     configure :user_id, :integer         # Hidden 
#   #     configure :provider, :string 
#   #     configure :uid, :string 
#   #     configure :uname, :string 
#   #     configure :uemail, :string 
#   #     configure :secret, :string 
#   #     configure :link, :string 
#   #     configure :name, :string 
#   #     configure :code, :string 
#   #     configure :access_token, :string 
#   #     configure :refresh_token, :string 
#   #     configure :access_token_expires_at, :time 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  BackgroundJob  ###

#   # config.model 'BackgroundJob' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your background_job.rb model definition

#   #   # Found associations:



#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :local_ip_address, :integer 
#   #     configure :total_job_time, :integer 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  Device  ###

#   # config.model 'Device' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device.rb model definition

#   #   # Found associations:

#   #     configure :device_model, :belongs_to_association 
#   #     configure :user, :belongs_to_association 
#   #     configure :audits, :has_many_association         # Hidden 
#   #     configure :device_location, :has_one_association 
#   #     configure :device_settings, :has_many_association 
#   #     configure :device_capability, :has_one_association 
#   #     configure :device_app_notification_settings, :has_many_association 
#   #     configure :device_events, :has_many_association 
#   #     configure :device_critical_commands, :has_many_association 
#   #     configure :shared_devices, :has_many_association 
#   #     configure :device_invitations, :has_many_association 
#   #     configure :extended_attributes, :has_many_association 
#   #     configure :device_free_trial, :has_one_association 
#   #     configure :recipes, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :name, :string 
#   #     configure :registration_id, :string 
#   #     configure :access_token, :string 
#   #     configure :time_zone, :float 
#   #     configure :plan_id, :string 
#   #     configure :plan_changed_at, :datetime 
#   #     configure :device_model_id, :integer         # Hidden 
#   #     configure :user_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :last_accessed_date, :datetime 
#   #     configure :deactivate, :boolean 
#   #     configure :target_deactivate_date, :datetime 
#   #     configure :mode, :enum 
#   #     configure :firmware_version, :string 
#   #     configure :relay_usage, :integer 
#   #     configure :stun_usage, :integer 
#   #     configure :upnp_usage, :integer 
#   #     configure :high_relay_usage, :boolean 
#   #     configure :relay_count, :integer 
#   #     configure :stun_count, :integer 
#   #     configure :upnp_count, :integer 
#   #     configure :relay_usage_reset_date, :datetime 
#   #     configure :latest_relay_usage, :float 
#   #     configure :deleted_at, :datetime 
#   #     configure :auth_token, :string 
#   #     configure :mac_address, :string 
#   #     configure :firmware_status, :integer 
#   #     configure :firmware_time, :datetime 
#   #     configure :host_ssid, :string 
#   #     configure :host_router, :string 
#   #     configure :upload_token, :string 
#   #     configure :upload_token_expires_at, :string 
#   #     configure :registration_at, :datetime 
#   #     configure :stream_name, :string 
#   #     configure :derived_key, :string 
#   #     configure :freetrial_notified_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceAppNotificationSetting  ###

#   # config.model 'DeviceAppNotificationSetting' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_app_notification_setting.rb model definition

#   #   # Found associations:

#   #     configure :app, :belongs_to_association 
#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :app_id, :integer         # Hidden 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :alert, :integer 
#   #     configure :is_enabled, :boolean 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceCapability  ###

#   # config.model 'DeviceCapability' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_capability.rb model definition

#   #   # Found associations:

#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :value, :serialized 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceCriticalCommand  ###

#   # config.model 'DeviceCriticalCommand' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_critical_command.rb model definition

#   #   # Found associations:

#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :command, :text 
#   #     configure :status, :string 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceEvent  ###

#   # config.model 'DeviceEvent' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_event.rb model definition

#   #   # Found associations:

#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :alert, :integer 
#   #     configure :time_stamp, :datetime 
#   #     configure :data, :text 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :value, :string 
#   #     configure :event_code, :text 
#   #     configure :deleted_at, :datetime 
#   #     configure :event_time, :string 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceFreeTrial  ###

#   # config.model 'DeviceFreeTrial' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_free_trial.rb model definition

#   #   # Found associations:



#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :device_registration_id, :string 
#   #     configure :user_id, :integer 
#   #     configure :plan_id, :string 
#   #     configure :trial_period_days, :integer 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :status, :string 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceInvitation  ###

#   # config.model 'DeviceInvitation' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_invitation.rb model definition

#   #   # Found associations:

#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :shared_by, :integer 
#   #     configure :shared_with, :string 
#   #     configure :invitation_key, :string 
#   #     configure :reminder_count, :integer 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceLocation  ###

#   # config.model 'DeviceLocation' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_location.rb model definition

#   #   # Found associations:

#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :local_ip, :string 
#   #     configure :local_port_1, :integer 
#   #     configure :local_port_2, :integer 
#   #     configure :local_port_3, :integer 
#   #     configure :local_port_4, :integer 
#   #     configure :remote_ip, :string 
#   #     configure :remote_port_1, :integer 
#   #     configure :remote_port_2, :integer 
#   #     configure :remote_port_3, :integer 
#   #     configure :remote_port_4, :integer 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :remote_iso_code, :string 
#   #     configure :remote_region_code, :integer 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceMaster  ###

#   # config.model 'DeviceMaster' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_master.rb model definition

#   #   # Found associations:

#   #     configure :device_master_batch, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :registration_id, :string 
#   #     configure :time, :datetime 
#   #     configure :firmware_version, :string 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :mac_address, :string 
#   #     configure :device_master_batch_id, :integer         # Hidden 
#   #     configure :hardware_version, :string 
#   #     configure :serial_number, :string 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceMasterBatch  ###

#   # config.model 'DeviceMasterBatch' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_master_batch.rb model definition

#   #   # Found associations:

#   #     configure :device_model, :belongs_to_association 
#   #     configure :creator, :belongs_to_association 
#   #     configure :updater, :belongs_to_association 
#   #     configure :device_master, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :file_name, :string 
#   #     configure :device_model_id, :integer         # Hidden 
#   #     configure :creator_id, :integer         # Hidden 
#   #     configure :updater_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceModel  ###

#   # config.model 'DeviceModel' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_model.rb model definition

#   #   # Found associations:

#   #     configure :device_type, :belongs_to_association 
#   #     configure :audits, :has_many_association         # Hidden 
#   #     configure :action_configs, :has_many_association 
#   #     configure :devices, :has_many_association 
#   #     configure :device_model_capabilities, :has_many_association 
#   #     configure :device_master_batches, :has_many_association 
#   #     configure :recipes, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :model_no, :string 
#   #     configure :name, :string 
#   #     configure :description, :string 
#   #     configure :device_type_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :deleted_at, :datetime 
#   #     configure :udid_scheme, :enum 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceModelCapability  ###

#   # config.model 'DeviceModelCapability' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_model_capability.rb model definition

#   #   # Found associations:

#   #     configure :device_model, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :firmware_prefix, :string 
#   #     configure :capability, :serialized 
#   #     configure :device_model_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceSetting  ###

#   # config.model 'DeviceSetting' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_setting.rb model definition

#   #   # Found associations:

#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :key, :string 
#   #     configure :value, :string 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  DeviceType  ###

#   # config.model 'DeviceType' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your device_type.rb model definition

#   #   # Found associations:

#   #     configure :audits, :has_many_association         # Hidden 
#   #     configure :associated_audits, :has_many_association         # Hidden 
#   #     configure :device_models, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :type_code, :string 
#   #     configure :name, :string 
#   #     configure :description, :string 
#   #     configure :capability, :serialized 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :deleted_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  EventLog  ###

#   # config.model 'EventLog' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your event_log.rb model definition

#   #   # Found associations:

#   #     configure :user, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :event_name, :string 
#   #     configure :event_description, :string 
#   #     configure :remote_ip, :string 
#   #     configure :registration_id, :string 
#   #     configure :user_agent, :string 
#   #     configure :time_stamp, :datetime 
#   #     configure :user_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  ExtendedAttribute  ###

#   # config.model 'ExtendedAttribute' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your extended_attribute.rb model definition

#   #   # Found associations:

#   #     configure :entity, :polymorphic_association 
#   #     configure :audits, :has_many_association         # Hidden 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :entity_type, :string         # Hidden 
#   #     configure :entity_id, :integer         # Hidden 
#   #     configure :key, :string 
#   #     configure :value, :text 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  MarketingContent  ###

#   # config.model 'MarketingContent' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your marketing_content.rb model definition

#   #   # Found associations:

#   #     configure :audits, :has_many_association         # Hidden 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :key, :string 
#   #     configure :value, :text 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :deleted_at, :time 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  PlanParameter  ###

#   # config.model 'PlanParameter' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your plan_parameter.rb model definition

#   #   # Found associations:

#   #     configure :subscription_plan, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :parameter, :string 
#   #     configure :value, :text 
#   #     configure :subscription_plan_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  Recipe  ###

#   # config.model 'Recipe' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your recipe.rb model definition

#   #   # Found associations:

#   #     configure :device_model, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :name, :string 
#   #     configure :program_code, :integer 
#   #     configure :default_duration, :string 
#   #     configure :min_duration, :string 
#   #     configure :max_duration, :string 
#   #     configure :device_model_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :deleted_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  RegistrationDetail  ###

#   # config.model 'RegistrationDetail' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your registration_detail.rb model definition

#   #   # Found associations:



#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :registration_id, :string 
#   #     configure :mac_address, :string 
#   #     configure :local_ip, :string 
#   #     configure :net_mask, :string 
#   #     configure :gateway, :string 
#   #     configure :remote_ip, :string 
#   #     configure :expire_at, :string 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  RelaySession  ###

#   # config.model 'RelaySession' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your relay_session.rb model definition

#   #   # Found associations:



#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :registration_id, :string 
#   #     configure :session_key, :string 
#   #     configure :stream_id, :string 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  SharedDevice  ###

#   # config.model 'SharedDevice' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your shared_device.rb model definition

#   #   # Found associations:

#   #     configure :primary_user, :belongs_to_association 
#   #     configure :secondary_user, :belongs_to_association 
#   #     configure :device, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :shared_by, :integer         # Hidden 
#   #     configure :shared_with, :integer         # Hidden 
#   #     configure :device_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  SubscriptionPlan  ###

#   # config.model 'SubscriptionPlan' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your subscription_plan.rb model definition

#   #   # Found associations:

#   #     configure :audits, :has_many_association         # Hidden 
#   #     configure :plan_parameters, :has_many_association 
#   #     configure :UserSubscription, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :plan_id, :string 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :price_cents, :integer 
#   #     configure :currency_unit, :string 
#   #     configure :renewal_period_month, :integer 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  User  ###

#   # config.model 'User' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your user.rb model definition

#   #   # Found associations:

#   #     configure :audits, :has_many_association         # Hidden 
#   #     configure :associated_audits, :has_many_association         # Hidden 
#   #     configure :authentications, :has_many_association 
#   #     configure :devices, :has_many_association 
#   #     configure :apps, :has_many_association 
#   #     configure :event_logs, :has_many_association 
#   #     configure :device_master, :has_many_association 
#   #     configure :devices_shared_by_me, :has_many_association 
#   #     configure :devices_shared_with_me, :has_many_association 
#   #     configure :user_subscriptions, :has_many_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :type, :string 
#   #     configure :birthday, :date 
#   #     configure :name, :string 
#   #     configure :roles_mask, :integer 
#   #     configure :email, :string 
#   #     configure :password, :password         # Hidden 
#   #     configure :password_confirmation, :password         # Hidden 
#   #     configure :reset_password_token, :string         # Hidden 
#   #     configure :reset_password_sent_at, :datetime 
#   #     configure :remember_created_at, :datetime 
#   #     configure :sign_in_count, :integer 
#   #     configure :current_sign_in_at, :datetime 
#   #     configure :last_sign_in_at, :datetime 
#   #     configure :current_sign_in_ip, :string 
#   #     configure :last_sign_in_ip, :string 
#   #     configure :failed_attempts, :integer 
#   #     configure :unlock_token, :string 
#   #     configure :locked_at, :datetime 
#   #     configure :authentication_token, :string 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :deleted_at, :datetime 
#   #     configure :upload_token, :string 
#   #     configure :upload_token_expires_at, :string 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end


#   ###  UserSubscription  ###

#   # config.model 'UserSubscription' do

#   #   # You can copy this to a 'rails_admin do ... end' block inside your user_subscription.rb model definition

#   #   # Found associations:

#   #     configure :user, :belongs_to_association 
#   #     configure :subscription_plan, :belongs_to_association 

#   #   # Found columns:

#   #     configure :id, :integer 
#   #     configure :user_id, :integer         # Hidden 
#   #     configure :plan_id, :string 
#   #     configure :subscription_uuid, :string 
#   #     configure :subscription_source, :string 
#   #     configure :deleted_at, :datetime 
#   #     configure :subscription_plan_id, :integer         # Hidden 
#   #     configure :created_at, :datetime 
#   #     configure :updated_at, :datetime 
#   #     configure :state, :string 
#   #     configure :expires_at, :datetime 

#   #   # Cross-section configuration:

#   #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #     # label_plural 'My models'      # Same, plural
#   #     # weight 0                      # Navigation priority. Bigger is higher.
#   #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

#   #   # Section specific configuration:

#   #     list do
#   #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #       # items_per_page 100    # Override default_items_per_page
#   #       # sort_by :id           # Sort column (default is primary key)
#   #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     end
#   #     show do; end
#   #     edit do; end
#   #     export do; end
#   #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
#   #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
#   #     # using `field` instead of `configure` will exclude all other fields and force the ordering
#   # end

# end
