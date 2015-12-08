class AddLatestRelayUsageToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :latest_relay_usage, :float,:default => 0
  end
end
