class AddTriggerOnDeviceEvents1 < ActiveRecord::Migration
  def change
  	execute <<-SQL
  		CREATE TRIGGER update_device_event_time 
      BEFORE INSERT ON device_events_1 FOR EACH ROW 
      BEGIN 
      IF NEW.event_time < '2000' THEN 
      SET NEW.event_time = NEW.time_stamp; 
      ELSE 
      SET NEW.event_time = CONVERT_TZ(New.event_time,(select timezone from device_timezones where New.device_id=device_id),'+0:00') ; 
      END IF;
      IF isnull(NEW.event_time) THEN
      SET NEW.event_time = NEW.time_stamp;
      END IF;
      END;
  	SQL
  end
end
