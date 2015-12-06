class DeviceEventDetail < ActiveRecord::Base
  
  include Grape::Entity::DSL
  
  belongs_to :device_events
  
  attr_accessible :clip_name, :device_event_id, :md5_sum 

end
