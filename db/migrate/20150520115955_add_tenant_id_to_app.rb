class AddTenantIdToApp < ActiveRecord::Migration
  def change
    add_column :apps,:tenant_id, :integer,:after =>:id,:default => 1
  end
end
