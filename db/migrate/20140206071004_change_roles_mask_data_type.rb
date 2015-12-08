class ChangeRolesMaskDataType < ActiveRecord::Migration
  def up
  	change_column :users, :roles_mask, :integer, :default => 2
  end

  def down
  	change_column :users, :roles_mask, :string
  end
end
