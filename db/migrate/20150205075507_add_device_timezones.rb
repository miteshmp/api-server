class AddDeviceTimezones < ActiveRecord::Migration
  def change
  	execute "create table device_timezones (device_id integer,timezone varchar(255),PRIMARY KEY ( device_id ));"
  	execute "insert into device_timezones select d.id,t.timezone from devices d,time_zone_mappings t where d.time_zone=t.timezone_float;"
  
  end
end
