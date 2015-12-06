class AddIndexToModelCapabilites < ActiveRecord::Migration
  def change
  	add_index :device_model_capabilities, [:device_model_id, :firmware_prefix],:unique => true, :name => "capability"
  end
end
