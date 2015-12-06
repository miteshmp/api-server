class AddTenantIdToDevice < ActiveRecord::Migration
  def change
    add_column :devices,:tenant_id, :integer,:after =>:id,:default => 1
  end
end
