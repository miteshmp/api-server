class AddTenantIdToSubscriptionPlan < ActiveRecord::Migration
  def change
    add_column :subscription_plans,:tenant_id, :integer,:after =>:plan_id,:default => 1
  end
end
