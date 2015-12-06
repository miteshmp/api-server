include StunHelper
include AwsHelper
include MandrillHelper
class FreeTrialEnforcer

  # Turn off MVR & send notification for devices for which free trial has expired
  def self.enforce_trial
    devices_free_trial = DeviceFreeTrial.where("status = '#{FREE_TRIAL_STATUS_ACTIVE}' AND (UNIX_TIMESTAMP(DATE_ADD(created_at, INTERVAL trial_period_days DAY)) - UNIX_TIMESTAMP(now()) < 0)").pluck(:device_registration_id)
    if (devices_free_trial.present? && devices_free_trial.length > 0)
      disable_mvr(devices_free_trial)
      device_records_updated = Device.where(registration_id: devices_free_trial).update_all(plan_id: Settings.default_device_plan, plan_changed_at: Time.now)
      free_trial_updated = DeviceFreeTrial.where("status = '#{FREE_TRIAL_STATUS_ACTIVE}' AND (UNIX_TIMESTAMP(DATE_ADD(created_at, INTERVAL trial_period_days DAY)) - UNIX_TIMESTAMP(now()) < 0)").update_all(status: FREE_TRIAL_STATUS_EXPIRED)
      Rails.logger.info "Updated #{free_trial_updated} free trial records at #{Time.now}"
      send_generic_mail("FreeTrialRoller run for #{Time.now}", "Updated #{device_records_updated} device records!\nUpdated #{free_trial_updated} free trial records!")
    end
    Rails.logger.info "Ran free trial enforcer for #{devices_free_trial.length} devices"
  end

  def self.disable_mvr(registration_id_list)
    if registration_id_list && registration_id_list.length > 0
      registration_id_list.each do |registration_id|
        begin
          device = Device.where(registration_id: registration_id).first
          # A device could have been removed after getting a free trial
          if device.present?
            # Turn off motion video recording
            device.toggle_mvr_command(false)
            # Send subscription info to device
            device.send_subscription_info(Settings.default_device_plan)
            # Send expiry notification
            FreeTrialNotifier.notify_expired_free_trial(device)
          end
        rescue Exception => e
          Rails.logger.error "Error in enforcing free trial for #{registration_id}. Continuing the process for other devices."
        end
      end
      Rails.logger.info "Turned off MVR for #{registration_id_list.length} devices"
    end
  end

end
