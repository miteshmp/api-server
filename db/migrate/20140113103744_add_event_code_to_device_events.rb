class AddEventCodeToDeviceEvents < ActiveRecord::Migration
  def change
    add_column :device_events, :event_code, :text
  end
end
