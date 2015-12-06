class UserSubscription < ActiveRecord::Base
  include RecurlyHelper
  include APIHelpers
  include AwsHelper
  include Grape::Entity::DSL

  belongs_to :user
  belongs_to :subscription_plan

  attr_accessible :subscription_uuid, :subscription_source, :state, :expires_at, :updated_at, :created_at

  entity do
    expose :plan_id
    expose :user_id
    expose :subscription_source
    expose :subscription_uuid
    expose :state
    expose :expires_at
  end
  validates_length_of :subscription_uuid, :minimum => 2, :allow_nil => false
  validate :plan_id_must_be_in_the_list


  def plan_id_must_be_in_the_list
    unless  SubscriptionPlan.where(plan_id: plan_id).first
      errors.add(:plan_id, "'%s' is invalid." % plan_id)
    end
  end

  def create_recurly_subscription(coupon_code, secret_token, currency_unit, user)
    if !self.plan_id.blank? && !user_id.blank?
      begin
        account = get_account(self.user_id)
        # By default, recurly creates an account (if the account doesn't exist) for a new subscription
        # But this account would lack details like email, first_name etc and hence we explicitly create
        # an account (if one doesn't exist) to capture these details before creating a subscription
        if !account.present?
          create_recurly_account(user)
        end
        subscription = create_subscription(coupon_code, self.plan_id, self.user_id, currency_unit, secret_token)
        self.subscription_uuid = subscription.uuid
        self.state = subscription.state
        self.save!
        subscription
      ensure
        ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
        ActiveRecord::Base.clear_active_connections!
      end
    end
  end

  def remove_pending(subscription_uuid, user_id)
    pending_plan = self.get_pending(subscription_uuid, user_id)
    if pending_plan.present?
      pending_plan.destroy
    end
  end

  def get_pending(subscription_uuid, user_id)
    UserSubscription.where(subscription_uuid: subscription_uuid, user_id: user_id, state: RECURLY_SUBSCRIPTION_STATE_PENDING).first
  end

  def record_pending(subscription_uuid, plan_id, user_id)
    pending_plan = get_pending(subscription_uuid, user_id)
    if !pending_plan.present?
      pending_plan = UserSubscription.new
    end
    pending_plan.state = RECURLY_SUBSCRIPTION_STATE_PENDING
    pending_plan.subscription_uuid = subscription_uuid
    pending_plan.plan_id = plan_id
    pending_plan.user_id = user_id
    pending_plan.subscription_source = "recurly"
    pending_plan.save!
  end

  def reactivate_recurly_subscription(subscription_uuid)
    begin
      subscription = reactivate_subscription(subscription_uuid)
      self.state = subscription.state
      self.expires_at = subscription.expires_at
      self.save!
      subscription
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      ActiveRecord::Base.clear_active_connections!
    end
  end

  def change_recurly_subscription(new_plan, is_cancelation, devices_ids, active_user)
    begin
      subscription = get_subscription_details(self.subscription_uuid)
      update_time_frame = "now"
      if !new_plan.blank? && !is_cancelation
        # Check if there's a downgrade and if so, do the change at the end of renewal cycle
        if (subscription.unit_amount_in_cents > new_plan.price_cents)
          update_time_frame = "renewal"
        end
        subscription = update_subscription(subscription, new_plan.plan_id, update_time_frame)
      elsif is_cancelation
        subscription = cancel_subscription(subscription)
        self.remove_pending(self.subscription_uuid, active_user.id)
      end
      self.state = subscription.state
      self.expires_at = subscription.expires_at
      if (update_time_frame == "now" && !is_cancelation)
        self.plan_id = new_plan.plan_id
        self.subscription_plan_id = new_plan.id
        self.remove_pending(self.subscription_uuid, active_user.id)
      elsif (update_time_frame == "renewal" && !is_cancelation)
        self.record_pending(self.subscription_uuid, new_plan.plan_id, active_user.id)
        self.expires_at = subscription.current_period_ends_at
      end
      self.save!
      if (devices_ids.present? && devices_ids.length > 0 && update_time_frame == "now")
        Device.apply_subscriptions(active_user, new_plan.plan_id, devices_ids)
      end
      subscription
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      ActiveRecord::Base.clear_active_connections!
    end
  end

end
