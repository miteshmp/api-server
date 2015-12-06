class AddMissingIndexToDeviceEvents < ActiveRecord::Migration
  def change
  	add_index :device_events, :time_stamp
  	add_index :device_events, :event_code, length: 30 
  	add_index :device_events, :alert
  	add_index :device_events, :deleted_at
  end
end
