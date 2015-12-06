class AddParentIdToDeviceEvents1 < ActiveRecord::Migration
  def change
    add_column :device_events_1, :parent_id, :integer
  end
end
