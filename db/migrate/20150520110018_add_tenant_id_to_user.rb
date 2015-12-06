class AddTenantIdToUser < ActiveRecord::Migration
  def change
        add_column :users,:tenant_id, :integer,:after =>:id,:default => 1
  end
end
