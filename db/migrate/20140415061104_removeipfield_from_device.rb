class RemoveipfieldFromDevice < ActiveRecord::Migration
  def change
  	remove_column :devices, :local_ip
  	remove_column :devices, :remote_ip
  end
end
