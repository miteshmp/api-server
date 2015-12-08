class RemoveDeviceCodeIndexFromApp < ActiveRecord::Migration
  def change
 	remove_index :apps, :device_code
  end
end
