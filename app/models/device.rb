include StunHelper
include RecurlyHelper
class Device < ActiveRecord::Base
  acts_as_paranoid
  include Grape::Entity::DSL
  extend Enumerize
  audited :associated_with => :user

  self.per_page = Settings.default_page_size

  has_one :device_location, :dependent => :destroy
  has_many :device_settings, :dependent => :destroy
  has_one :device_capability, :dependent => :destroy
  has_many :device_app_notification_settings, :dependent => :destroy
  has_many :device_events, :dependent => :destroy
  has_many :device_critical_commands, :dependent => :destroy
  has_many :shared_devices, :dependent => :destroy
  has_many :device_invitations, :dependent => :destroy
  belongs_to :user
  belongs_to :device_model
  

  attr_accessible :name, :id, :registration_id, :mac_address,:device_type, :master_key, :time_zone, :device_model_id, :mode, :firmware_version, :plan_id, :plan_changed_at, :last_accessed_date, :deactivate, :target_deactivate_date, :upnp_usage, :stun_usage, :relay_usage, :upnp_count, :stun_count, :relay_count, :high_relay_usage, :relay_usage_reset_date, :latest_relay_usage, :auth_token

  attr_accessor :is_available
  attr_accessor :snaps_url 
  attr_accessor :signature

  enumerize :mode, :in => { upnp: 1, stun: 2, relay: 3, relay_tcp: 5 }, :default => :upnp, :scope =>  :having_modes
  

  entity :id,
  :name,
  :registration_id,
  :mac_address,
  :time_zone do
    expose :is_available, if: { type: :full }
    expose :snaps_url, if: { type: :full }
    expose :device_model_id,if: { type: :full }
    expose :mode, if: { type: :full }
    expose :firmware_version, if: { type: :full }
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
    expose :user_id, if: { type: :full }
    expose :device_location, :using => DeviceLocation::Entity, if: { type: :full }
    expose :device_settings, :using => DeviceSetting::Entity, if: { type: :full }
  end
  validates :registration_id, :allow_nil => false, uniqueness: { case_sensitive: false }
  validates :mac_address, :allow_nil => false, uniqueness: { case_sensitive: false }

  validate :device_model_must_be_in_the_list
  validates :name, :length => { :in => 5..30 }
  validate :time_zone_must_be_in_the_list

  validates :firmware_version, format: { with: /^\d+.\d+(.\d+)?$/,
    message: Settings.invalid_format_message }
  validates :name, format: { with: /\A[a-zA-Z0-9_.-]*\z/,
    message: Settings.invalid_format_message }
  validates :registration_id, format: { with: /\A[a-zA-Z0-9_=&.]*\z/,
    message: Settings.invalid_format_message }
  validates :mac_address, format: { with: /\A[a-zA-Z0-9_=&.]*\z/,
    message: Settings.invalid_format_message }             

  after_create :send_plan_id, :create_recurly_account # Todo: Need to add subscription_plan after creating account

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
      command = Settings.camera_commands.set_subscription_plan_command % self.plan_id
      send_command_over_stun(self, command)   
    }   
  end

  def send_downgrade_streaming_video_quality_command
    command = Settings.camera_commands.downgrade_streaming_video_quality
    send_command_over_stun(self, command) 
  end 

  def create_recurly_account
    Thread.new {
    response = create_recurly_device_account(self)
   }
   
   
  end 

  def generate_token
    self.auth_token = loop do
      random_token = SecureRandom.urlsafe_base64(12)
      break random_token unless Device.exists?(auth_token: random_token)
    end
  end

end
