class AddUdidSchemeToDeviceModel < ActiveRecord::Migration
  def change
    add_column :device_models, :udid_scheme, :integer,:default => 1
  end
end
