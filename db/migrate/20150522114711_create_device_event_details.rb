class CreateDeviceEventDetails < ActiveRecord::Migration
  def change
    create_table :device_event_details do |t|
      t.string :clip_name
      t.string :md5_sum
      t.references :device_event
      t.timestamps
    end
  end
end
