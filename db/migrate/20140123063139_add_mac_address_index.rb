class AddMacAddressIndex < ActiveRecord::Migration
  def change
    add_index :devices, :mac_address, :unique => true
  end
end
