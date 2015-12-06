class CreateDeviceCapabilities < ActiveRecord::Migration
  def change
    create_table :device_capabilities do |t|
      t.integer :device_id
      t.text :value

      t.timestamps
    end
  end
end
