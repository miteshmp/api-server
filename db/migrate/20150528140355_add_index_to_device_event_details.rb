class AddIndexToDeviceEventDetails < ActiveRecord::Migration
  def change
    add_index :device_event_details, :device_event_id
  end
end
