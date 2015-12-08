class AddValueToDeviceEvents < ActiveRecord::Migration
  def change
    add_column :device_events, :value, :string
  end
end
