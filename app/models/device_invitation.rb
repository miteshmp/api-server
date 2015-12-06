class DeviceInvitation < ActiveRecord::Base
	include Grape::Entity::DSL
	belongs_to :device

  	attr_accessible :id, :invitation_key, :reminder_count, :shared_by, :shared_with
  	entity :id,
  	:shared_by,
  	:shared_with,
  	:reminder_count,
  	:created_at,
    :updated_at do
      expose :device, :using => Device::Entity
  end

  validates_uniqueness_of :device_id, :scope => [:shared_by, :shared_with],message: "share invitation already sent."


  def generate_invitation_key
    self.invitation_key = loop do
      random_token = SecureRandom.urlsafe_base64(48)
      break random_token unless DeviceInvitation.exists?(invitation_key: random_token)
    end
  end

end
