class RemoveReferenceTestBatchFromMaster < ActiveRecord::Migration
  def change
  	change_table :device_masters do |t|
      t.remove_references :device_test_batch
    end
  end
  
end
