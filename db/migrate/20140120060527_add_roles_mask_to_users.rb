class AddRolesMaskToUsers < ActiveRecord::Migration
  def change
    add_column :users, :roles_mask, :integer,:default => 2
  end
end
