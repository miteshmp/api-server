class CreateUserSubscriptions < ActiveRecord::Migration
  def change
    create_table :user_subscriptions do |t|
      t.integer :user_id
      t.string :plan_id
      t.string :subscription_uuid
      t.string :subscription_source
      t.timestamp :deleted_at

      t.references :subscription_plan
      t.timestamps
    end
  end
end
