class AddDeviceInfoToDeviceLocation < ActiveRecord::Migration
  def change
  	add_column :device_locations, :remote_iso_code,    :string, :default => nil
	add_column :device_locations, :remote_region_code, :integer,:default => 1
  end
end
