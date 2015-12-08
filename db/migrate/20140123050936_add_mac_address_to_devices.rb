class AddMacAddressToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :mac_address, :string
  end
end
