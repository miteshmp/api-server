class AddStatusToDeviceFreeTrials < ActiveRecord::Migration
  def change
    add_column :device_free_trials, :status, :string
  end
end
