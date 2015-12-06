class DeviceSetting < ActiveRecord::Base
  include Grape::Entity::DSL
  
  belongs_to :device
  
  attr_accessible :key, :value, :device_id

  entity :key, 
  :value, 
  # :created_at, 
  :updated_at do
  end
end