class DropDeviceFirmwares < ActiveRecord::Migration
  def up
  	drop_table :device_firmwares
  end

  def down
  end
end
