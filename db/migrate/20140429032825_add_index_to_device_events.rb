class AddIndexToDeviceEvents < ActiveRecord::Migration
  def change
    add_index :device_events, :device_id
  end
end
