class DeviceCriticalCommand < ActiveRecord::Base
	include Grape::Entity::DSL

   belongs_to :device
  attr_accessible :command, :status
  entity :id,
  :device_id,
  :command,
  :status,
  :created_at,
  :updated_at do
    
  end
end
