class App < ActiveRecord::Base
  include Grape::Entity::DSL
  extend Enumerize

  self.per_page = Settings.default_page_size

  enumerize :notification_type, :in => { none: 0, gcm: 1, apns: 2 },  :default => :none, scope: :having_notification_type

  attr_accessible :id, :name, :notification_type, :sns_endpoint, :user_id, :device_code, :software_version
  has_many :device_app_notification_settings, :dependent => :destroy
  belongs_to :user

  entity :id,
  :name,
  :software_version,
  :notification_type,
  :registration_id,
  :sns_endpoint,
  :user_id,
  :device_code,
  :created_at,
  :updated_at do
    expose :device_app_notification_settings
  end

  validates :device_code, :length => { :in => 3..255 }, :allow_nil => false, uniqueness: { case_sensitive: false, scope: :user_id  }
  validates :name, :length => { :in => 3..100 }
  validates :software_version, :length => { :in => 2..10}
end
