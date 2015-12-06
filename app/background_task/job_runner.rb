require 'socket'
require 'ipaddr'

include MandrillHelper
class JobRunner

  # The background task is built to run jobs on one instance, at any given time,
  # whose ip address has the lowest integer value when compared to its peers
  def self.run_tasks
    begin
      if Rails.env.production?
        begin
          ip = HTTParty.get("http://169.254.169.254/latest/meta-data/local-ipv4").parsed_response
        rescue Exception => e
          Rails.logger.error "Unable to get ip address on time. Defaulting to random number for instance selection"
        end
      else
        ipv4 = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
        ip = ipv4.ip_address unless !ipv4.present?
      end
      ip_integer = nil
      if ip
        # convert ip to an integer value
        ip_integer = IPAddr.new(ip).to_i
      else
        ip_integer = Random.rand(10000)
      end
      if ip_integer
        # save info for a potential job in the db
        save_job(ip_integer, 0)
        sleep(5)
        # select the ip that has the lowest value
        selected_ip = BackgroundJob.where("date(created_at) = '#{Time.now.utc.to_date}'").order(:local_ip_address).pluck(:local_ip_address).first
        if selected_ip && selected_ip == ip_integer
          Rails.logger.info "Selected ip: #{ip} #{selected_ip} for background job"
          start = Time.now
          # remove multiple job potentials since they were created to select an instance to run the job
          BackgroundJob.where("date(created_at) = '#{Time.now.utc.to_date}'").delete_all

          # The following jobs need to execute independent of errors raised in control flow
          begin
            FreeTrialEnforcer.enforce_trial
          rescue Exception => e
            handle_exception(e, "Error in Background job's FreeTrialEnforcer")
          end

          begin
            FreeTrialNotifier.notify_unused_free_trial
          rescue Exception => e
            handle_exception(e, "Error in Background job's FreeTrialNotifier.notify_unused_free_trial")
          end

          begin
            FreeTrialNotifier.notify_expiring_free_trial
          rescue Exception => e
            handle_exception(e, "Error in Background job's FreeTrialNotifier.notify_expiring_free_trial")
          end

          EventsCleaner.remove_objects
          # save job details to the db for future reference
          save_job(ip_integer, (Time.now - start))
          Rails.logger.info "Completed background job"
        end
      end
    rescue Exception => e
      handle_exception(e, "Background JobRunner Error")
    end

  end

  def self.handle_exception(e, email_subject)
  	Rails.logger.error "Error while running Background job"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    send_generic_mail(email_subject, "Error While running a background job in #{Rails.env}.\n #{e.backtrace.join("\n")}")
  end

  def self.save_job(ip_integer, total_time)
    bg_job = BackgroundJob.new
    bg_job.local_ip_address = ip_integer
    bg_job.total_job_time = total_time
    bg_job.save!
  end
end
