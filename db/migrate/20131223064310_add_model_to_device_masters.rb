class AddModelToDeviceMasters < ActiveRecord::Migration
  def change
    change_table :device_masters do |t|
      t.references :device_model
    end
  end
  
end
