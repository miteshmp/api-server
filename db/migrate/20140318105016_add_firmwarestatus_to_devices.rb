class AddFirmwarestatusToDevices < ActiveRecord::Migration
  def change
  	add_column :devices, :firmware_status, :integer,:default => 0
  end
end
