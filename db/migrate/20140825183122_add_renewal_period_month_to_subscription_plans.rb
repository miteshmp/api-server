class AddRenewalPeriodMonthToSubscriptionPlans < ActiveRecord::Migration
  def change
    add_column :subscription_plans, :renewal_period_month, :integer
  end
end
