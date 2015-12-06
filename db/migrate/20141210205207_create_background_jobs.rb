class CreateBackgroundJobs < ActiveRecord::Migration
  def change
    create_table :background_jobs do |t|
      t.integer :local_ip_address, :limit => 8
      t.integer :total_job_time

      t.timestamps
    end
  end
end
