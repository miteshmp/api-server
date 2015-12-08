class RemoveFirmwareVersionFromDevice < ActiveRecord::Migration
  def up
    remove_column :devices, :firmware_version
  end

  def down
    add_column :devices, :firmware_version, :string
  end
end
