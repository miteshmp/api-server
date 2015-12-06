class CreateDeviceCriticalCommands < ActiveRecord::Migration
  def change
    create_table :device_critical_commands do |t|
      t.text :command
      t.string :status
      t.references :device

      t.timestamps
    end
  end
end
