class AddDeletedAtToDeviceTypes < ActiveRecord::Migration
  def change
    add_column :device_types, :deleted_at, :time
  end
end
