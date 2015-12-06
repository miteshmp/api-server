class CreateDeviceLocations < ActiveRecord::Migration
  def change
    create_table :device_locations do |t|
      t.string :local_ip
      t.integer :local_port_1
      t.integer :local_port_2
      t.integer :local_port_3
      t.integer :local_port_4
      t.string :remote_ip
      t.integer :remote_port_1
      t.integer :remote_port_2
      t.integer :remote_port_3
      t.integer :remote_port_4
      t.references :device
      t.timestamps
    end
    add_index :device_locations, :device_id, :unique => true
  end
end
