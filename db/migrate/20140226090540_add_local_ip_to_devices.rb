class AddLocalIpToDevices < ActiveRecord::Migration
  def change
  	add_column :devices, :local_ip, :string
  end
end
