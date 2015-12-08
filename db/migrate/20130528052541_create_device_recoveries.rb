class CreateDeviceRecoveries < ActiveRecord::Migration
  def change
    create_table :device_recoveries do |t|
      t.integer :recovery_type
      t.string :requested_from_ip
      t.integer :count
      t.integer :status
      t.references :device
      t.timestamps
    end
    add_index :device_recoveries, :device_id
  end
end
