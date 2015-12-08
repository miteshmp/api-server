class DropDeviceRecoveries < ActiveRecord::Migration
  def up
  	drop_table :device_recoveries
  end

  def down
  end
end
