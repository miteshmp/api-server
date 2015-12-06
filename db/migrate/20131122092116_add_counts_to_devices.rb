class AddCountsToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :relay_count, :integer,:default => 0
    add_column :devices, :stun_count, :integer,:default => 0
    add_column :devices, :upnp_count, :integer,:default => 0
  end
end
