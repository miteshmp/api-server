class RecurlyWebhooksAPI_v1 < Grape::API
  version 'v1', :using => :path,  :format => :xml
  format :xml
  formatter :json, SuccessFormatter
  helpers RecurlyHelper
  helpers AwsHelper
  helpers MandrillHelper

  resource :recurly do

    desc "Recurly push notification"
    post 'recurly_push_notification' do
      case params.keys[0]

      when "canceled_subscription_notification"
        subscription = params["canceled_subscription_notification"]["subscription"]
        if subscription.present?
          user_sub = UserSubscription.where(subscription_uuid: subscription.uuid).first()
          #  Discrepancy found! Send email and update the state
          if (user_sub.blank? || user_sub.state != subscription.state)
            send_recurly_exception_mail(params, "Discrepancy found in user's subscription: #{user_sub}")
          end
        end

      when "new_subscription_notification"
        subscription = params["new_subscription_notification"]["subscription"]
        account = params["new_subscription_notification"]["account"]
        if subscription.present?
          current_subscription = UserSubscription.where('state != ?', RECURLY_SUBSCRIPTION_STATE_EXPIRED).where('user_id = ?', account.account_code).first
          if current_subscription.present? 
            send_recurly_exception_mail(params, "Error - Subscription created in recurly for a user with active subscription")
          end
          handle_recurly_subscription(params["new_subscription_notification"]["subscription"], account.account_code)
        end

        # We use this webhook to downgrade a user's devices at the end of renewal cycle for canceled plans
      when "expired_subscription_notification"
        begin
          subscription = params["expired_subscription_notification"]["subscription"]
          handle_expiry_webhook(subscription, Settings.expired_subscription_msg % subscription.plan.plan_code)
        rescue Exception => e
          send_recurly_exception_mail(params, "Error with expiry notification: #{e.message}")
        end

      when "updated_subscription_notification"
        begin
          subscription = params["updated_subscription_notification"]["subscription"]
          handle_downgrade_webhook(subscription)
        rescue Exception => e
          send_recurly_exception_mail(params, "Error with updated_subscription_notification: #{e.message}")
        end

      when "failed_payment_notification"
        begin
          subscription = params["new_subscription_notification"]["subscription"]
          handle_expiry_webhook(subscription, Settings.failed_subscription_payment_msg % subscription.plan.plan_code)
          send_recurly_exception_mail(params, "Downgraded all devices due to failed payment for subscription!")
        rescue Exception => e
          send_recurly_exception_mail(params, "Unable to downgrade devices for failed payment: #{e.message}")
        end

      when "void_payment_notification"
        send_recurly_exception_mail(params, "Void payment notification received!")

      end
      # status 200
      {:status => 200}
    end
  end

end
