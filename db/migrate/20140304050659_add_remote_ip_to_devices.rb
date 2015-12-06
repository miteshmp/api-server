class AddRemoteIpToDevices < ActiveRecord::Migration
  def change
  	add_column :devices, :remote_ip, :string
  end
end
