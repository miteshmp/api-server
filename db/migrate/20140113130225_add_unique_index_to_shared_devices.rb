class AddUniqueIndexToSharedDevices < ActiveRecord::Migration
  def change
  	add_index :shared_devices, [:shared_by, :shared_with, :device_id],:unique => true, :name => "shared_device"
  end
end
