class AddIndexToDeviceCriticalCommands < ActiveRecord::Migration
  def change
  	add_index :device_critical_commands, :device_id
  end
end
