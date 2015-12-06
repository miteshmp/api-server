class AddSerialNumbertoDeviceMaster < ActiveRecord::Migration
  def change
	add_column :device_masters, :serial_number, :string,:default => 0
  end
end
