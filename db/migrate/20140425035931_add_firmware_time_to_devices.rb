class AddFirmwareTimeToDevices < ActiveRecord::Migration
  def change
  	add_column :devices, :firmware_time, :datetime,:default => nil
  end
end
