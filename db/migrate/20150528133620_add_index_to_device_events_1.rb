class AddIndexToDeviceEvents1 < ActiveRecord::Migration
  def change
    add_index :device_events_1, :parent_id
  end
end
