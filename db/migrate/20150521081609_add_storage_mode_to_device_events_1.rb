class AddStorageModeToDeviceEvents1 < ActiveRecord::Migration
  def change
    add_column :device_events_1, :storage_mode, :integer
  end
end
