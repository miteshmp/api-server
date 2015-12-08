class AddUniqueIndexToSubscriptionPlan < ActiveRecord::Migration
  def change
  	add_index :subscription_plans, :plan_id, :unique => true
  end
end
