class BackgroundJob < ActiveRecord::Base
  attr_accessible :local_ip_address, :total_job_time
end
