class DeviceFreeTrial < ActiveRecord::Base
	include Grape::Entity::DSL
	attr_accessible :status, :trial_period_days, :updated_at, :created_at

	validate :device_registration_id, :allow_nil => false
	validate :plan_id, :allow_nil => false
	validate :user_id, :allow_nil => false
	validate :status, :allow_nil => false

	entity :id,
		:plan_id,
		:status,
		:trial_period_days,
		:created_at,
		:updated_at do
		expose :device_registration_id, if: { type: :complete }
		expose :user_id, if: { type: :complete }
	end

end
