class AddIndexToDeviceModels < ActiveRecord::Migration
  def change
  	add_index :device_models, :device_type_id
  end
end
