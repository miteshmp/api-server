class SubscriptionPlan < ActiveRecord::Base
  include Grape::Entity::DSL
  include RecurlyHelper
  audited

  has_many :plan_parameters, :dependent => :destroy
  has_many :UserSubscription

  attr_accessible :id, :price_cents, :currency_unit, :renewal_period_month, :tenant_id

  entity :id,
    :plan_id,
    :tenant_id,
    :price_cents,
    :currency_unit,
    :renewal_period_month,
    :created_at,
  :updated_at do
    expose :plan_parameters, :using => PlanParameter::Entity
  end

  validates :plan_id, :allow_nil => false, uniqueness: { case_sensitive: false }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, less_than: 100000}
  validates :renewal_period_month, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 12}
  validates :plan_id, format: { with: /\A[a-zA-Z0-9._-]+\z/,
                                message: Settings.invalid_format_message }

  def create_recurly_plan(plan_id, plan_price_cents, currency_unit, renewal_period_month,tenant_id)
    begin
      exist_plan = get_plan(plan_id)
      Rails.logger.info("exist_plan: #{exist_plan}")
      if exist_plan.present?
        # There should atleast be one currency unit for each plan
        self.currency_unit =  exist_plan.unit_amount_in_cents.keys[0]
        self.price_cents = exist_plan.unit_amount_in_cents.values[0]
        self.plan_id = exist_plan.plan_code
        self.renewal_period_month = exist_plan.plan_interval_length
      else
        plan = create_plan(plan_id, plan_price_cents, currency_unit, renewal_period_month, "months")
        self.currency_unit =  currency_unit
        self.price_cents = plan_price_cents
        self.plan_id = plan_id
        self.renewal_period_month = renewal_period_month
      end
      self.tenant_id = tenant_id if tenant_id
      self.save!
      self
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
      ActiveRecord::Base.clear_active_connections! ;
    end
  end

  def delete_recurly_plan
    begin
      plan = delete_plan(self.plan_id)
      self.destroy
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
      ActiveRecord::Base.clear_active_connections! ;
    end
  end

  def update_recurly_plan(price_cents)
    begin
      plan = update_plan(self.plan_id, price_cents, self.currency_unit)
      self.price_cents = price_cents
      self.save!
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
      ActiveRecord::Base.clear_active_connections! ;
    end
  end
end
