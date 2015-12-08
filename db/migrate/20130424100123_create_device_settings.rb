class CreateDeviceSettings < ActiveRecord::Migration
  def change
    create_table :device_settings do |t|
      t.string :key
      t.string :value
      t.references :device
      t.timestamps
    end
    add_index :device_settings, [:device_id, :key], :unique => true
  end
end
