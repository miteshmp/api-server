class AddEventTimeToDeviceEvents < ActiveRecord::Migration
  def change
  	add_column :device_events, :event_time, :string,:default => nil
  end
end
