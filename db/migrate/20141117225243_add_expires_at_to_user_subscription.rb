class AddExpiresAtToUserSubscription < ActiveRecord::Migration
  def change
  	add_column :user_subscriptions, :expires_at, :timestamp
  end
end
