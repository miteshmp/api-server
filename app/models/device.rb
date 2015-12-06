include StunHelper
include RecurlyHelper
include AwsHelper
class Device < ActiveRecord::Base
  acts_as_paranoid
  include Grape::Entity::DSL
  extend Enumerize
  audited :associated_with => :user,except: [:auth_token, :upload_token, :derived_key, :access_token]

  self.per_page = Settings.default_page_size

  has_one :device_location, :dependent => :destroy
  has_many :device_settings, :dependent => :destroy
  has_one :device_capability, :dependent => :destroy
  has_many :device_app_notification_settings, :dependent => :destroy
  has_many :device_events, :dependent => :destroy
  has_many :device_critical_commands, :dependent => :destroy
  has_many :shared_devices, :dependent => :destroy
  has_many :device_invitations, :dependent => :destroy
  has_many :extended_attributes, as: :entity
  has_one :device_free_trial, :primary_key => :registration_id, :foreign_key => "device_registration_id", :conditions => proc { "user_id = #{self.user_id}" } # We need this relation since a device can have more than 1 free trial
  belongs_to :user
  belongs_to :device_model
  has_many :recipes, :through => :device_model
  has_many :children, class_name: "Device",
                          foreign_key: "parent_id"

  belongs_to :parent, class_name: "Device"                          
  attr_accessible :name, :id,:tenant_id, :registration_id, :mac_address,:device_type, :master_key, :time_zone, :device_model_id, :mode, :firmware_version, :plan_id, :plan_changed_at, :last_accessed_date, :deactivate, :target_deactivate_date, :upnp_usage, :stun_usage, :relay_usage, :upnp_count, :stun_count, :relay_count, :high_relay_usage, :relay_usage_reset_date, :latest_relay_usage, :auth_token, :firmware_status,:firmware_time,:host_ssid,:host_router,
                  :upload_token,:upload_token_expires_at,:registration_at, :freetrial_notified_at

  enumerize :mode, :in => { upnp: 1, stun: 2, relay: 3, relay_tcp: 5, p2p: 6, presence_detection: 7, motion_detection: 8 }, :default => :upnp, :scope =>  :having_modes

  attr_accessor :is_available
  attr_accessor :snaps_url
  attr_accessor :snaps_modified_at
  attr_accessor :signature

  after_destroy :delete_from_external_server


  entity :id,
  :name,
  :registration_id,
  :mac_address,
  :time_zone do
    expose :is_available, if: { type: :full }
    expose :snaps_url, if: { type: :full }
    expose :snaps_modified_at, if: { type: :full }
    expose :device_model_id,if: { type: :full }
    expose :mode, if: { type: :full }
    expose :parent ,using: ParentDevice
    expose :firmware_version, if: { type: :full }
    expose :firmware_status, if: { type: :full}
    expose :firmware_time, if: { type: :full}
    expose :plan_id, if: { type: :full }
    expose :plan_changed_at, if: { type: :full }
    expose :last_accessed_date, if: { type: :full }
    expose :deactivate, if: { type: :full }
    expose :target_deactivate_date, if: { type: :full }
    expose :upnp_usage, if: { type: :full }
    expose :stun_usage, if: { type: :full }
    expose :relay_usage, if: { type: :full }
    expose :upnp_count, if: { type: :full }
    expose :stun_count, if: { type: :full }
    expose :relay_count, if: { type: :full }
    expose :high_relay_usage, if: { type: :full }
    expose :relay_usage_reset_date, if: { type: :full }
    expose :latest_relay_usage, if: { type: :full }
    expose :created_at, if: { type: :full }
    expose :updated_at, if: { type: :full }
    expose :registration_at, if: { type: :full }
    expose :user_id, if: { type: :full }
    expose :host_ssid, if: { type: :full }
    expose :host_router, if: { type: :full }
    expose :device_attributes, :as => :attributes,if: { type: :full }
    expose :device_location, :using => DeviceLocation::Entity, if: { type: :full }
    expose :device_settings, :using => DeviceSetting::Entity, if: { type: :full }
    expose :device_free_trial, :using => DeviceFreeTrial::Entity, type: :full, if: { type: :full }
    expose :tenant_id, if: { type: :full }
  end

  validates :registration_id, :allow_nil => false, uniqueness: { case_sensitive: false }
  validates :mac_address, :allow_nil => false, uniqueness: { case_sensitive: false }

  validates :stream_name,:allow_nil => true, uniqueness: { case_sensitive: false }

  validate :device_model_must_be_in_the_list
  validates :name, :length => { :in => 5..30 }
  validate :time_zone_must_be_in_the_list

  validates :firmware_version, format: { with: /^\d+.\d+(.\d+)?$/,
    message: Settings.invalid_format_message }
  validates :name, format: { with: /\A[a-zA-Z0-9_. \-']*\z/,
    message: Settings.invalid_format_message }
  validates :registration_id, format: { with: /\A[a-zA-Z0-9_=&.]*\z/,
    message: Settings.invalid_format_message }
  validates :mac_address, format: { with: /\A[a-zA-Z0-9_=&.]*\z/,
    message: Settings.invalid_format_message }             

  after_create :send_plan_id # Todo: Need to add subscription_plan after creating account

  def device_attributes
    attributes = {}
    self.extended_attributes.map {|attribute| attributes[attribute.key] = attribute.value}
    attributes
  end  

  def time_zone_must_be_in_the_list
    unless time_zone.in?([-12.00,-11.00,-10.00,-9.30,-9.00,-8.00,-7.00,-6.00,-5.00,-4.30,-4.00,-3.30,-3.00,-2.00,-1.00,0.00,1.00,2.00,3.00,3.30,4.00,4.30,5.00,5.30,5.45,6.00,6.30,7.00,8.00,8.45,9.00,9.30,10.00,10.30,11.00,11.30,12.00,12.45,13.00,14.00])
      errors.add(:time_zone, "'%s' is invalid." % time_zone)
    end
  end

  def device_model_must_be_in_the_list
    unless  DeviceModel.where(id: device_model_id).first
      errors.add(:device_model_id, "'%s' is invalid." % device_model_id)
    end
  end 

  def send_plan_id

    Thread.new {

      begin
        send_subscription_info(self.plan_id)
        rescue Exception => exception
        ensure
          ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
          ActiveRecord::Base.clear_active_connections! ;
      end
    }   
  end

  def delete_from_external_server
    external_notifier = ExternalNotifier.new({:device => self})
    external_notifier.device_delete({:device => self})
  end  

  def send_downgrade_streaming_video_quality_command
    command = Settings.camera_commands.downgrade_streaming_video_quality
    send_command_over_stun(self, command) 
  end 

  def generate_token
    
    self.auth_token = loop do
      random_token = SecureRandom.urlsafe_base64(12)
      break random_token unless Device.exists?(auth_token: random_token)
    end
  
  end

  # Method :- generate_derived_key
  # Description :- Derived key is associated with device & it is used for encryption and local authentication
  # Version Support :- Device firmware version >= 01.xx.xx
  def generate_derived_key ( master_key )

    derived_key = Array.new(16) ;

    counter = 0 ;

    master_key.each_byte { | base_character|
      
      derived_key[counter] = HubbleConfiguration::DERIVED_KEY_BASE[ base_character % HubbleConfiguration::DERIVED_KEY_BASE.length];
      counter = counter + 1 ;

    }
    return derived_key.join;

  end

  # Method :- generate_stream_name
  # Description :- Stream name MUST be unique throught platform
  # Version support :- Device Firmware version >= 01.xx.xx
  def generate_stream_name()

    stream_name = nil ;

    if self.stream_name == nil

      begin

        stream_name = SecureRandom.hex(HubbleConfiguration::STREAM_NAME_LENGTH);
        continue_loop = Device.exists?(stream_name: stream_name) ;

      end while continue_loop ;

    else
      stream_name = self.stream_name ;

    end
    return stream_name ;
  end

  # Method :- save_stream_name
  # Description :- This method is used to store stream name in to activerecord
  def save_stream_name(relay_rtmp_session_url)

    # rtmp url :- "rtmp://54.179.68.189:1935/camera/blinkhd.44334C5FF091.stream"
    session_url_array =  relay_rtmp_session_url.split("/",5) ;

    # ip address validation will be done later on
    session_rtmp_ip = session_url_array[2].split(":")[0];

    stream_name = (session_url_array[4].split(".")[1]);

    if (stream_name != nil)

      # store stream name into database which is used to close session & authenticate media stream
      self.stream_name = stream_name ;

      # save record in database
      self.save! ;

    end
  end

  # Method :- clear_stream_name
  # Description :- This is used to clear stream name from activerecord
  def clear_stream_name()

    begin

      self.stream_name = nil ;
      self.save! ;

      rescue Exception => exception
        Rails.logger.error(exception.to_s) ;
    end
  end


  # Method :- generate_upload_token
  # Description :- Device service should get "upload_token" from API server to upload files into Upload Server.
  #                Without upload token, device is not able to upload any files into S3 bucket.
  # Version support :- Device firmware version >= 01.14.00
  def generate_upload_token

    random_upload_token = nil ;

    begin
      random_upload_token = SecureRandom.urlsafe_base64(HubbleConfiguration::DEVICE_UPLOAD_TOKEN_LENGTH);
      continueLoop = Device.exists?(upload_token: random_upload_token);
    end while continueLoop ;
    
    return random_upload_token;
  end

  # Method :- hasValid_UploadToken
  # Description :- Every Upload token which was given to device will expire after 12 hours. It is required that device
  #                should get new token for uploading files when token is expired.
  # Version support :- Device firmware version >= 01.14.00

  def hasValid_UploadToken
    # check that Upload token did not expire
    if ( self.upload_token_expires_at &&  ( self.upload_token_expires_at.to_i > Time.now.utc.to_i) )
      return true; 
    end
    return false;
  end

  # Method :- get_upload_token_expire_time
  # Description :- Every upload token should expire after every 12 hours.
  # Version support :- Device firmware version >= 01.14.00
  def get_upload_token_expire_time

    expire_time = Time.now.utc.to_i + HubbleConfiguration::DEVICE_UPLOAD_TOKEN_EXPIRE_TIME_SECONDS ;
    return expire_time.to_s; 

  end

  # Method :- _set_default_value_for_enumerized_attributes
  def _set_default_value_for_enumerized_attributes
    begin
      super
    rescue ActiveModel::MissingAttributeError => exception
      Rails.logger.error("_set_default_value_for_enumerized_attributes :-  #{exception.message}");
    end
  end

  # Method :- _validate_enumerized_attributes
  def _validate_enumerized_attributes
    begin
      super
    rescue ActiveModel::MissingAttributeError => exception
      Rails.logger.error("_validate_enumerized_attributes :-  #{exception.message}");
    end
  end

  def toggle_mvr_command(on = true)
    if on
      command = Settings.camera_commands.mvr_toggle % "11"
    else
      command = Settings.camera_commands.mvr_toggle % "00"
    end
    send_command_over_stun(self, command) 
  end

  def apply_free_trial(plan_id)
    self.plan_id = plan_id
    self.plan_changed_at = Time.now
    self.save!
  end

  def send_subscription_info(plan_id)
    command = Settings.camera_commands.set_subscription % plan_id
    send_command_over_stun(self, command)
  end

  # @param active_user The user for which subscription information is needed
  # @return Subscription information for a user which includes device availability for each plan
  def self.get_subscriptions(active_user)
    begin
      devices = active_user.devices.select("registration_id, plan_id, name").all
      device_plans = Hash.new(0)
      devices.each do |device|
        device_plans[device.plan_id] += 1
      end
      user_subscriptions = active_user.user_subscriptions.all
      plan_device_availability = Hash.new
      user_subscriptions.each do |subscription|
        max_devices_plan = PlanParameter.select("value").where(parameter: PLAN_PARAMETER_MAX_DEVICES_FIELD, subscription_plan_id: subscription.subscription_plan_id).first()
        if (!max_devices_plan.blank? && subscription.state != 'expired')
          plan_device_availability[subscription.plan_id] = max_devices_plan.value.to_i - device_plans[subscription.plan_id]
        end
      end
      {
        :devices => devices,
        :plan_device_availability => plan_device_availability
      }
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      ActiveRecord::Base.clear_active_connections!
    end
  end

  # @param devices_registration_ids Array fo registration_ids of devices that need subscription changes
  # @param new_plan_id The subscription plan that needs to be applied to the devices
  # @param user_id The user id that needs subscription changes
  # All the devices revert to default the plan as defined in settings
  def self.change_subscriptions(new_plan_id, devices_registration_ids, user_id)
    begin
      device_count = self.where(registration_id: devices_registration_ids, user_id: user_id).count
      if (device_count.blank? || device_count != devices_registration_ids.length)
        raise StandardError, "Invalid device registration_id found in: #{devices_registration_ids.join(', ')}"
      else
        Device.where(registration_id: devices_registration_ids, user_id: user_id).update_all(:plan_id => new_plan_id, :plan_changed_at => Time.now)
        devices_registration_ids.each do |registration_id|
          applied_device = Device.where(registration_id: registration_id).first()
          if applied_device.present?
            # We send a push notification only when a paid subscription is applied to a device
            send_subscription_notification(applied_device, Settings.subscription_applied_msg % [applied_device.plan_id, applied_device.name], EventType::SUBSCRIPTION_APPLIED, 0, nil) unless applied_device.plan_id == Settings.default_device_plan
            # Send plan_id to device
            applied_device.send_plan_id
          end
        end
      end
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      ActiveRecord::Base.clear_active_connections!
    end
  end

  def self.selective_downgrade(old_plan_id, new_plan_id, new_subscription_plan_id, user_id)
    begin
      devices = self.where(user_id: user_id, plan_id: old_plan_id).pluck(:registration_id)
      if (devices.count > 0)
        new_plan_max_device = PlanParameter.where(:subscription_plan_id => new_subscription_plan_id, parameter: PLAN_PARAMETER_MAX_DEVICES_FIELD).pluck(:value).first
        if (!new_plan_max_device.blank? && devices.count > new_plan_max_device = new_plan_max_device.to_i)
          # Change extra devices to default plan
          change_subscriptions(Settings.default_device_plan, devices.slice(new_plan_max_device, devices.length-1), user_id)
          devices = devices.slice(0, new_plan_max_device)
        end
        change_subscriptions(new_plan_id, devices, user_id)
      end
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      ActiveRecord::Base.clear_active_connections!
    end
  end

  # @param active_user The user that needs subscription changes
  # @param new_plan_id The subscription plan that needs to be applied to the user's devices
  # @param devices_registration_ids Array fo registration_ids of devices that need subscription changes
  def self.apply_subscriptions(active_user, plan_id, devices_registration_ids)
    begin
      avail_subs = get_subscriptions(active_user)
      if (avail_subs[:plan_device_availability][plan_id].blank?)
        raise StandardError, "No active subscription found for #{plan_id}!"
      elsif (devices_registration_ids.length > avail_subs[:plan_device_availability][plan_id])
        raise StandardError, "Available devices for #{plan_id}: #{avail_subs[:plan_device_availability][plan_id]}"
      end
      change_subscriptions(plan_id, devices_registration_ids, active_user.id)
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      ActiveRecord::Base.clear_active_connections!
    end
  end

  # Creates a new free trial for the device
  # All conditional checks for creating free trial must be performed by the caller
  # @param trial_plan Hubble plan for which free trial needs to be created
  def create_free_trial(trial_plan = nil)
    trial_plan ||= Settings.free_trial_plan
    apply_free_trial(trial_plan)
    device_free_trial = DeviceFreeTrial.new
    device_free_trial.device_registration_id = self.registration_id
    device_free_trial.user_id = self.user_id
    device_free_trial.plan_id = trial_plan
    device_free_trial.trial_period_days = Settings.free_trial_days
    device_free_trial.status = FREE_TRIAL_STATUS_ACTIVE
    device_free_trial.save!
    self.send_plan_id
    Thread.new do
      send_subscription_notification(self, Settings.freetrial_applied_msg % self.name, EventType::FREE_TRIAL_APPLIED, Settings.free_trial_days, nil)
      # Turn on MVR
      toggle_mvr_command(true)
      ActiveRecord::Base.connection.close
    end
    return device_free_trial
  end

end
