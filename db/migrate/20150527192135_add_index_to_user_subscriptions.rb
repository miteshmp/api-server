class AddIndexToUserSubscriptions < ActiveRecord::Migration
  def change
  	add_index :user_subscriptions, :user_id
  	add_index :user_subscriptions, :state
  	add_index :user_subscriptions, :subscription_uuid
  end
end
