class AddRelayUsageResetDateToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :relay_usage_reset_date, :datetime
  end
end
