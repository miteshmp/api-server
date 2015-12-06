class AddDeviceModelToActionConfigs < ActiveRecord::Migration
  def change
    
    add_column :action_configs, :device_model_id, :integer
    add_index :action_configs, :device_model_id

    device_model = DeviceModel.where(model_no: HubbleDeviceModel::FOCUS66).first ;
    if device_model
    	ActionConfig.where('device_model_id IS NULL OR device_model_id = 0').update_all(device_model_id: device_model.id);
    end
  end
end
