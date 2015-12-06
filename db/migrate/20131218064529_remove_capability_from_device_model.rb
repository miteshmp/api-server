class RemoveCapabilityFromDeviceModel < ActiveRecord::Migration
  def up
    remove_column :device_models, :capability
  end

  def down
    add_column :device_models, :capability, :text
  end
end
