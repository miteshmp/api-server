class CreateDeviceEvents < ActiveRecord::Migration
  def change
    create_table :device_events do |t|
      t.integer :alert
      t.datetime :time_stamp
      t.text :data
      t.references :device

      t.timestamps
    end
  end
end
