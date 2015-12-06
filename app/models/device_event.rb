class DeviceEvent < ActiveRecord::Base
 # Delete event when device is removed from account OR register again.
 # acts_as_paranoid
  include Grape::Entity::DSL
  self.table_name ='device_events_1'
  self.primary_keys = :id,:device_id
  belongs_to :device
  has_many :device_event_details, :dependent => :destroy
  
  attr_accessible :alert, :data, :time_stamp, :value, :event_code,:event_time,:storage_mode
  

  entity :alert,
  		 :value,
  		 :event_code,
  		 :data,
       :storage_mode, 
  		 :time_stamp do 
  		 end

end
