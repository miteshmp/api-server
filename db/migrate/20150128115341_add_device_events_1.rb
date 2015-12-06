class AddDeviceEvents1 < ActiveRecord::Migration
  def change
  	if !ActiveRecord::Base.connection.table_exists? 'device_events_1'
	  	create_table :device_events_1 do |t|
	      t.integer :alert
	      t.datetime :time_stamp
	      t.text :data
	      t.references :device
	      t.timestamps
	      t.string :value
	      t.text :event_code
	      t.datetime :deleted_at
	      t.datetime :event_time
	    end
	end

	add_index :device_events_1, :device_id
	add_index :device_events_1, :time_stamp
  	add_index :device_events_1, :event_code, length: 30 
  	add_index :device_events_1, :alert
  	add_index :device_events_1, :deleted_at
  	add_index :device_events_1, :event_time
  end
end