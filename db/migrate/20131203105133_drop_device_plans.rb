class DropDevicePlans < ActiveRecord::Migration
  def up
  	drop_table :device_plans
  end

  def down
  end
end
