class AddTenantIdToDeviceModel < ActiveRecord::Migration
  def change
    add_column :device_models,:tenant_id, :integer,:after =>:id,:default => 1
  end
end
