class AddFirmwareVersionToDevice < ActiveRecord::Migration
  def change
    add_column :devices, :firmware_version, :string, :default => "1"
  end
end
