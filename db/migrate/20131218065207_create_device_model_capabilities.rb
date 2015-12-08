class CreateDeviceModelCapabilities < ActiveRecord::Migration
  def change
    create_table :device_model_capabilities do |t|
      t.string :firmware_prefix
      t.text :capability
      t.references :device_model

      t.timestamps
    end
  end
end
