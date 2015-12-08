class CreateDeviceAccessibilities < ActiveRecord::Migration
  def change
    create_table :device_accessibilities do |t|
      t.integer :mode
      t.references :device

      t.timestamps
    end
    add_index :device_accessibilities, [:device_id, :mode], :unique => true
  end
end
