class CreateDeviceFreeTrials < ActiveRecord::Migration
  def change
    create_table :device_free_trials do |t|
      t.string :device_registration_id
      t.integer :user_id
      t.string :plan_id
      t.integer :trial_period_days
      
      t.timestamps
    end
  end
end
