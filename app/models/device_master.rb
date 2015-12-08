class DeviceMaster < ActiveRecord::Base
  include Grape::Entity::DSL	
  attr_accessible :firmware_version, :hardware_version, :registration_id, :time, :mac_address

  belongs_to :device_master_batch

  entity :registration_id,
  :mac_address,
  :firmware_version,
  :hardware_version,
  :time,
  :created_at,
  :updated_at do 
  end

end
