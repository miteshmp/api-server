class CreateDeviceFirmwares < ActiveRecord::Migration
  def change
    create_table :device_firmwares do |t|
      t.string :version
      t.references :device

      t.timestamps
    end
    add_index :device_firmwares, :device_id, :unique => true
  end
end
