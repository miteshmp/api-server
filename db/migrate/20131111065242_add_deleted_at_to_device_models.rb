class AddDeletedAtToDeviceModels < ActiveRecord::Migration
  def change
    add_column :device_models, :deleted_at, :time
  end
end
