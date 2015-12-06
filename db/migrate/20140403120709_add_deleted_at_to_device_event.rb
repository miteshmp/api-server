class AddDeletedAtToDeviceEvent < ActiveRecord::Migration
  def change
    add_column :device_events, :deleted_at, :datetime
  end
end
