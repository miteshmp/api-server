class CreateDeviceMasterBatches < ActiveRecord::Migration
  def change
    create_table :device_master_batches do |t|
      t.string :file_name
      t.references :device_model

      t.userstamps
      t.timestamps
    end
  end
end
