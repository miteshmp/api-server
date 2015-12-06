class CreatePartitions < ActiveRecord::Migration
  def change
  	execute <<-SQL
		ALTER TABLE device_events_1 PARTITION BY HASH(device_id) PARTITIONS 100;
    SQL
  end
end
