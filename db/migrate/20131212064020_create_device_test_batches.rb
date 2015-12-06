class CreateDeviceTestBatches < ActiveRecord::Migration
  def change
    create_table :device_test_batches do |t|
      t.string :time
      t.string :user_name
      t.string :device_test_batch
      t.references :user

      t.timestamps
    end
  end
end
