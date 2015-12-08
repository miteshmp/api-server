class AddIndexToDeviceMasters < ActiveRecord::Migration
  def change
  	add_index :device_masters, :mac_address, :unique => true
  	add_index :device_masters, :registration_id, :unique => true
  end
end
