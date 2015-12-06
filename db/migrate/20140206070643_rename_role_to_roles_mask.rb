class RenameRoleToRolesMask < ActiveRecord::Migration
  def change
  	rename_column :users, :role, :roles_mask
	User.update_all("roles_mask = 64", "roles_mask = 4");
	User.update_all("roles_mask = 4",  "roles_mask = 3");
  end
end
