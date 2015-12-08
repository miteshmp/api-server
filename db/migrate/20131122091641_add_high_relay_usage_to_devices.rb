class AddHighRelayUsageToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :high_relay_usage, :boolean,:default => false
  end
end
