class AddIndexToDeviceCapabilities < ActiveRecord::Migration
  def change
  	add_index :device_capabilities, :device_id
  end
end
