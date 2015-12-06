class AddReferenceDeviceMasterBatchToMaster < ActiveRecord::Migration
  def change
  	change_table :device_masters do |t|
      t.references :device_master_batch
    end
  end
end
