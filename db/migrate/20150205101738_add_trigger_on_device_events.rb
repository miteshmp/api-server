class AddTriggerOnDeviceEvents < ActiveRecord::Migration
  def up
  	# Insert the record coming into device_events into device_event_1
  	execute <<-SQL
  		CREATE TRIGGER insert_device_events_1
		AFTER INSERT ON device_events FOR EACH ROW
		BEGIN
		INSERT INTO device_events_1 (alert,time_stamp,data,device_id,created_at,updated_at,value,event_code,deleted_at,event_time) VALUES (new.alert,new.time_stamp,new.data,new.device_id,new.created_at,new.updated_at,new.value,new.event_code,new.deleted_at,new.event_time); 
		END;
	SQL
  end
end
