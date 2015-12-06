module RecurlyHelper

  # @param user The user object for whom a new account needs to be created
  # @return The created account object
  def create_recurly_account(user)
    begin
      account = Recurly::Account.create(
        :account_code => user.id,
        :email        => user.email,
        :first_name   => user.name
      )
    rescue Exception => e
      Rails.logger.error "Exception while creating a recurly account for user: #{user.to_json} with exception: #{e.message}"
    end
  end

  # @param account_id The Recurly account id for which the information needs to be updated
  # @param recurly_secret The secret token corresponding to a user's account info that's stored in Recurly
  # @return The updated account object
  def update_recurly_account(account_id, recurly_secret)
    account = get_account(account_id)
    if (!account.blank?)
      account = account.update_attributes(
        :billing_info => {:token_id => recurly_secret }
      )
    end
  end

  # @id The id of the account that needs itss billing info
  # @return Billing info object
  def get_recurly_billing(account_id)
    Recurly::BillingInfo.find account_id
  end

  # @id The id of the account that needs to be found
  # @return The account object
  def get_account(id)
    begin
      account = Recurly::Account.find id
    rescue Recurly::Resource::NotFound => e
      Rails.logger.error " Error with finding recurly account with id: #{id} & message: #{e.message}"
    end
    account
  end

  # @param plan_code The unique plan_code for the new plan
  # @param unit_amount_in_cents The price to be charged for the plan
  # @param currency The default currency unit for the new plan
  # @param renewal_interval Plan interval length
  # @param renewal_unit The unit that defines the renewal_interval like 'days', 'months'
  # @return The created Recurly plan object
  def create_plan(plan_code, unit_amount_in_cents, currency, renewal_interval, renewal_unit)
    plan = Recurly::Plan.create(
      :plan_code            => plan_code,
      :name                 => plan_code,
      :unit_amount_in_cents => { currency => unit_amount_in_cents },
      :plan_interval_length => renewal_interval,
      :plan_interval_unit   => renewal_unit
    )
    check_recurly_error(plan)
  end

  def get_plan(plan_id)
    begin
      Recurly::Plan.find(plan_id)
    rescue Exception => e
      Rails.logger.error e.message
      return false
    end
  end

  def delete_plan(plan_code)
    plan = Recurly::Plan.find(plan_code)
    plan.destroy
    check_recurly_error(plan)
  end

  def update_plan(plan_code, unit_amount_in_cents, currency)
    plan = Recurly::Plan.find(plan_code)
    plan.unit_amount_in_cents[currency] = unit_amount_in_cents
    plan.save
    check_recurly_error(plan)
  end

  # @param uuid The unique id of an existing subscription that needs to be updated
  # @return The Recurly subscription object
  def get_subscription_details(uuid)
    Recurly::Subscription.find(uuid)
  end

  # @param coupon_code The recurly coupon code that needs to applied while creatign the subscription
  # @param plan_code The plan_code that needs to be applied for the new subscription
  # @param account_code The account for which the subscription needs to be created
  # @param currency The currency unit for the new subscription
  # @param secret_token The secret_token returned by recurly that contains billing info
  # @return The created Recurly subscription object
  def create_subscription(coupon_code, plan_code, account_code, currency, secret_token)
    account_info = { :account_code => account_code }
    if (!secret_token.blank?)
      account_info = {:account_code => account_code, :billing_info => {:token_id => secret_token } }
    end
    sub_params = {
      :plan_code => plan_code,
      :currency  => currency,
      :account   => account_info
    }
    if coupon_code.present?
      sub_params[:coupon_code] = coupon_code
    end
    subscription = Recurly::Subscription.create(sub_params)
    check_recurly_error(subscription)
  end

  # @param recurly_subscription The recurly subscription object that needs to be updated
  # @param plan_code The new plan_code that needs to be applied for the subscription
  # @param time_frame The time frame by which the subscription needs to be updated
  # @return The modified Recurly subscription object
  def update_subscription(recurly_subscription, plan_code, time_frame)
    if (recurly_subscription.present?)
      recurly_subscription.update_attributes(
        :plan_code => plan_code,
        :timeframe => time_frame
      )
      check_recurly_error(recurly_subscription)
    end
  end


  # @param recurly_subscription The recurly subscription object that needs to be updated
  # @return The modified Recurly subscription object
  def cancel_subscription(recurly_subscription)
    if (recurly_subscription.present?)
      recurly_subscription.cancel
      check_recurly_error(recurly_subscription)
    end
  end

  # @param uuid The unique id of an existing subscription that needs to be updated
  # @return The modified Recurly subscription object
  def reactivate_subscription(uuid)
    subscription = Recurly::Subscription.find(uuid)
    subscription.reactivate
    check_recurly_error(subscription)
  end

  # @param subscription The subscription object that was sent by recurly as a webhook
  # This notification can be triggered when a payment fails or a user's subscription got expired
  # through cancelation or when a subscription is terminated through Reculy interface. In all cases,
  # we update the subscription object and change all the user's devices to the default freemium plan
  def handle_expiry_webhook(subscription, msg)
    user_sub = UserSubscription.where(subscription_uuid: subscription.uuid).where("state = '#{RECURLY_SUBSCRIPTION_STATE_ACTIVE}' or state = '#{RECURLY_SUBSCRIPTION_STATE_CANCELED}'").first()
    recurly_sub = get_subscription_details(subscription.uuid)
    if (user_sub.blank?)
      raise "Subscription uuid not found in Hubble!"
    elsif (recurly_sub.state == subscription.state)
      user_sub.state = recurly_sub.state
      user_sub.save!
      user_sub.remove_pending(user_sub.subscription_uuid, user_sub.user_id)
      Device.where(user_id: user_sub.user_id, plan_id: user_sub.plan_id).update_all(:plan_id => Settings.default_device_plan, :plan_changed_at => Time.now)
      user_devices = user_sub.user.devices
      if user_devices.present? && user_devices.length > 0
        # Send subscription expiry to each of the user's devices
        user_devices.each do |device|
          device.send_subscription_info(Settings.default_device_plan)
        end
        AwsHelper::send_subscription_notification(user_devices.first, msg, EventType::SUBSCRIPTION_CANCELED, 0, subscription.plan.plan_code)
      end
    end
  end

  # @param subscription The subscription object that was sent by recurly as a webhook
  def handle_downgrade_webhook(subscription)
    user_sub = UserSubscription.where(subscription_uuid: subscription.uuid, state: RECURLY_SUBSCRIPTION_STATE_ACTIVE).first()
    recurly_sub = get_subscription_details(subscription.uuid)
    if (!user_sub.blank? && !recurly_sub.blank? && user_sub.plan_id != recurly_sub.plan_code)
      old_subscription_plan = SubscriptionPlan.where(id: user_sub.subscription_plan_id).first
      new_subscription_plan = SubscriptionPlan.where(plan_id: recurly_sub.plan_code).first
      if (new_subscription_plan.blank?)
        raise "Uknown plan received from recurly: #{recurly_sub}"
      end
      if (recurly_sub.unit_amount_in_cents < old_subscription_plan.price_cents)
        Device.selective_downgrade(user_sub.plan_id, recurly_sub.plan_code, new_subscription_plan.id, user_sub.user_id)
      end
      user_sub.plan_id = recurly_sub.plan_code
      user_sub.subscription_plan_id = new_subscription_plan.id
      user_sub.state = recurly_sub.state
      user_sub.save!
      if (!recurly_sub.pending_subscription.present?)
        user_sub.remove_pending(user_sub.subscription_uuid, user_sub.user_id)
      end
    else
      raise "Discrepancy with subscriptions! UserSubscription: #{user_sub.to_json}, RecurlySubscription: #{recurly_sub.to_json}"
    end
  end

  # @param subscription The subscription object that was sent by recurly as a webhook
  def handle_recurly_subscription(subscription, account_code)
    recurly_sub = get_subscription_details(subscription.uuid)
    user = User.where(id: account_code).first()
    plan = SubscriptionPlan.where(plan_id: recurly_sub.plan_code).first()
    exist_subscn = UserSubscription.where(subscription_uuid: recurly_sub.uuid)
    if user.present? && !exist_subscn.present?
      user_subscription = UserSubscription.new
      user_subscription.plan_id = recurly_sub.plan_code
      user_subscription.subscription_plan_id = plan.id
      user_subscription.user_id = user.id
      user_subscription.subscription_source = "recurly-direct"
      user_subscription.subscription_uuid = recurly_sub.uuid
      user_subscription.state = recurly_sub.state
      user_subscription.save!
      Rails.logger.info "Recorded a new subscription created directly in recurly"
    end
  end

  # @param subscription A Recurly subscription object from which data needs to be extracted
  # @return A standard response that contains necessary subscription information
  def get_subscription_data(subscription)
    if !subscription.blank?
      pending_subscription = Hash.new
      if !subscription.pending_subscription.blank?
        pending_subscription = {:subscription_price_cents => subscription.pending_subscription.unit_amount_in_cents,
                                :subscription_plan => subscription.pending_subscription.plan_code}
      end
      {
        :subscription_state => subscription.state,
        :subscription_price_cents => subscription.unit_amount_in_cents,
        :subscription_uuid => subscription.uuid,
        :subscription_plan => subscription.plan_code,
        :current_period_ends_at => subscription.current_period_ends_at,
        :pending_subscription => pending_subscription
      }
    end
  end

  # @param recurly_object The object/response that's returned by Recurly for any action
  # @return The input recurly object & exception in case of errors
  def check_recurly_error(recurly_object)
    error = recurly_object.errors
    # Recurly doesn't throw exception for client errors (like 422) and hence need to explicitly check for http status code.
    error_code = recurly_object.response.code
    if (!error.blank?)
      message = "Recurly error! "
      error.each do |key, value|
        message += "[#{key}] #{value.join(", ")}! "
      end
      raise message
    elsif (!error_code.blank? && error_code.to_i >299)
      raise "Recurly error! #{error_code} - #{recurly_object.response.message}"
    else
      recurly_object
    end
  end

end
