class DeviceAppNotificationSetting < ActiveRecord::Base
  
    include Grape::Entity::DSL

  belongs_to :app
  belongs_to :device
  attr_accessible :alert, :is_enabled
  
  validates :alert, :uniqueness => {:scope => [:app_id, :device_id]}
  
  validate :alert_must_be_defined_in_device_capability

  entity :alert, 
  :is_enabled, 
  :device_id, 
  :app_id, 
  :id,
  :created_at,
  :updated_at do
  end
    
  
 
  def alert_must_be_defined_in_device_capability
    # if !expiration_date.blank? and expiration_date < Date.today
    #   errors.add(:expiration_date, "can't be in the past")
    # end
  end

end
