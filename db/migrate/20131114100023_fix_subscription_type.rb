class FixSubscriptionType < ActiveRecord::Migration
  def change
    rename_column :devices, :subscription_type, :plan_id
  end
end
