class RemoveModelReferenceFromDeviceMaster < ActiveRecord::Migration
  def change
  	change_table :device_masters do |t|
      t.remove_references :device_model
    end
  end
end
