class AddPrimaryKeyToDeviceEvents1 < ActiveRecord::Migration
  def change
  	execute "ALTER TABLE device_events_1 CHANGE COLUMN `device_id` `device_id` INT(11) NOT NULL ,DROP PRIMARY KEY,ADD PRIMARY KEY (`id`, `device_id`);"
  end
end
