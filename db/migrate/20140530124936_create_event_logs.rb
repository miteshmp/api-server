class CreateEventLogs < ActiveRecord::Migration
  def change

    create_table :event_logs do |t|
    	
    	t.string :event_name
    	t.string :event_description
    	t.string :remote_ip
    	t.string :registration_id
    	t.string :user_agent
    	t.datetime :time_stamp
      	t.references :user

		t.timestamps
    end
    add_index :event_logs, :user_id
  end
end
