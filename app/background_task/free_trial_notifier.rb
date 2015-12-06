include MandrillHelper
class FreeTrialNotifier

  # Communicate once that a free trial is available for a device
  def self.notify_unused_free_trial
    Rails.logger.info "Running notification for unused trials"
    counter = 0
    devices_avail_freetrial = Device.where(freetrial_notified_at: nil, plan_id: Settings.default_device_plan).pluck(:registration_id)
    devices_avail_freetrial.each do |registration_id|
      device_free_trial = DeviceFreeTrial.where(device_registration_id: registration_id).first()
      if !device_free_trial.present?
        device = Device.where(registration_id: registration_id).first()
        if device.present?
          subscn_app = device.user.apps.where(app_unique_id: [SUBSCRIPTION_SUPPORTED_APPS["gcm"], SUBSCRIPTION_SUPPORTED_APPS["apns"]]).first()
          if subscn_app.present?
            begin
              send_subscription_notification(device, Settings.freetrial_available_msg % device.name, EventType::FREE_TRIAL_AVAILABLE, 0, nil)
              device_user = device.user
              send_free_trial_mail(device_user.email, device.name, device_user.name)
              Device.where(registration_id: registration_id).update_all(freetrial_notified_at: Time.now())
              counter += 1
            rescue Exception => e
              Rails.logger.error "Unable to notify available free trial for #{device.registration_id}. Continuing the process for other devices."
            end
          end
        end
      end
    end
    Rails.logger.info "Sent #{counter} free trial available notifications"
  end

  def self.notify_expiring_free_trial
    Rails.logger.info "Running notification for expiring trials"
    counter = 0
    devices_expiring = DeviceFreeTrial.where("status = '#{FREE_TRIAL_STATUS_ACTIVE}' AND DATEDIFF(DATE_ADD(created_at, INTERVAL trial_period_days DAY), now()) <= 3").pluck(:device_registration_id)
    devices_expiring.each do |registration_id|
      device = Device.where(registration_id: registration_id).first()
      if (device.present? && (!device.freetrial_notified_at.present? || device.freetrial_notified_at < 3.days.ago))
        begin
          send_subscription_notification(device, Settings.freetrial_expiring_msg % [3, device.name], EventType::FREE_TRIAL_EXPIRY_PENDING, 3, nil)
          Device.where(registration_id: registration_id).update_all(freetrial_notified_at: Time.now())
          device_user = device.user
          send_free_trial_expiring_mail(device_user.email, device.name, device_user.name)
          counter += 1
        rescue Exception => e
          Rails.logger.error "Unable to notify expiring free trial for #{device.registration_id}. Continuing the process for other devices."
        end
      end
    end
    Rails.logger.info "Sent #{counter} free trial expiring notifications"
  end

  # Send expiry notification
  def self.notify_expired_free_trial(device)
    device_user = device.user
    send_free_trial_expired_mail(device_user.email, device.name, device_user.name)
    send_subscription_notification(device, Settings.freetrial_expired_msg % device.name, EventType::FREE_TRIAL_EXPIRED, 0, nil)
  end

end
