class DeviceEvent < ActiveRecord::Base
  include Grape::Entity::DSL
  belongs_to :device
  attr_accessible :alert, :data, :time_stamp, :value, :event_code
  

  entity :alert,
  		 :value,
  		 :event_code,
  		 :data,
  		 :time_stamp do 
  		 end

end
