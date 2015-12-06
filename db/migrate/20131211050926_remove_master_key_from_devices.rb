class RemoveMasterKeyFromDevices < ActiveRecord::Migration
  def up
    remove_column :devices, :master_key
  end

  def down
    add_column :devices, :master_key, :string
  end
end
