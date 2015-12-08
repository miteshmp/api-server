class DevicePlan < ActiveRecord::Base
    include Grape::Entity::DSL
    
  belongs_to :device
  belongs_to :plan
  attr_accessible :device_id, :plan_id  
  
  entity :plan_id, 
  :device_id, 
  :created_at, 
  :updated_at do
  end
end
