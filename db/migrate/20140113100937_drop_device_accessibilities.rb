class DropDeviceAccessibilities < ActiveRecord::Migration
  def up
  	drop_table :device_accessibilities
  end

  def down
  end
end
