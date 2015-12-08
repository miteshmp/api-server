class AddUsageParametersToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :relay_usage, :integer,:default => 0
    add_column :devices, :stun_usage, :integer,:default => 0
    add_column :devices, :upnp_usage, :integer,:default => 0
  end
end
