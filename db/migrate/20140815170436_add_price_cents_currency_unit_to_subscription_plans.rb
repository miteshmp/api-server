class AddPriceCentsCurrencyUnitToSubscriptionPlans < ActiveRecord::Migration
  def change
    add_column :subscription_plans, :price_cents, :integer
    add_column :subscription_plans, :currency_unit, :string
  end
end
