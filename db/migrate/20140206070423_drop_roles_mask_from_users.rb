class DropRolesMaskFromUsers < ActiveRecord::Migration
  def change
  	remove_column :users, :roles_mask
  end
end
