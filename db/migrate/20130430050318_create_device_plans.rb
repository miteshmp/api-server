class CreateDevicePlans < ActiveRecord::Migration
  def change
    create_table :device_plans do |t|
      t.integer :device_id
      t.integer :plan_id
      t.integer :user_id

      t.timestamps
    end
  end
end
