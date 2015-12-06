class AddIndexToDeviceFreeTrials < ActiveRecord::Migration
  def change
    add_index :device_free_trials, :device_registration_id
    add_index :device_free_trials, :user_id
    add_index :device_free_trials, :status
  end
end
