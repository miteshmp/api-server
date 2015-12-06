class DeviceLocation < ActiveRecord::Base
  include Grape::Entity::DSL
  belongs_to :device

  attr_accessible :local_ip, 
  :local_port_1,
  :local_port_2, 
  :local_port_3, 
  :local_port_4, 
  :remote_ip, 
  :remote_port_1,
  :remote_port_2, 
  :remote_port_3, 
  :remote_port_4, 
  :device_id,
  :remote_iso_code,
  :remote_region_code
  

  entity :remote_ip, 
  :remote_port_1,
  :remote_port_2, 
  :remote_port_3, 
  :remote_port_4, 
  :local_ip,   
  :local_port_1,
  :local_port_2, 
  :local_port_3, 
  :local_port_4 do
 # :created_at, 
 # :updated_at do
  end

end