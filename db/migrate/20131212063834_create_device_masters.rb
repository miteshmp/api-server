class CreateDeviceMasters < ActiveRecord::Migration
  def change
    create_table :device_masters do |t|
      t.string :registration_id
      t.string :report
      t.string :time
      t.string :hardware_version
      t.string :firmware_version
      t.string :model_no
      t.references :device_test_batch

      t.timestamps
    end
  end
end
