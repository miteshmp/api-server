class AddMacAddressToDeviceMasters < ActiveRecord::Migration
  def change
    add_column :device_masters, :mac_address, :string
  end
end
