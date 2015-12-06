class AddStateToUserSubscriptions < ActiveRecord::Migration
  def change
    add_column :user_subscriptions, :state, :string
  end
end
