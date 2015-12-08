class SubscriptionPlan < ActiveRecord::Base
	include Grape::Entity::DSL

	has_many :plan_parameters, :dependent => :destroy

  	attr_accessible :id, :plan_id

  	entity :id, 
  	:plan_id, 
  	:created_at, 
  	:updated_at do
  		 expose :plan_parameters, :using => PlanParameter::Entity
  end

  validates :plan_id, :allow_nil => false, uniqueness: { case_sensitive: false }
  validates :plan_id, format: { with: /\A[a-zA-Z0-9._-]+\z/,
    message: Settings.invalid_format_message }
end
