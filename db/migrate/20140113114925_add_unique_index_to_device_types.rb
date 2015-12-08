class AddUniqueIndexToDeviceTypes < ActiveRecord::Migration
  def change
  	add_index :device_types, :type_code, :unique => true
  end
end
