class AddTriggerOnDevices < ActiveRecord::Migration
  def change
  	# First trigger inserts the new device timezone details into device_timezones table
  	# Second trigger updates the device_timezones table on update of the devices timezone column
  	execute <<-SQL
  		CREATE TRIGGER insert_device_timezones AFTER INSERT ON devices FOR EACH ROW 
		BEGIN 
		INSERT INTO device_timezones VALUES(New.id,(select timezone from time_zone_mappings where New.time_zone=timezone_float)); 
		END;
  	SQL
  	execute <<-SQL
		CREATE TRIGGER update_device_timezones AFTER UPDATE ON devices FOR EACH ROW 
		BEGIN
		if NEW.time_zone <> OLD.time_zone
		THEN
		UPDATE device_timezones set timezone=(select timezone from time_zone_mappings where New.time_zone=timezone_float) where device_id=New.id;
		END IF; 
		END;
  	SQL
  end
end
