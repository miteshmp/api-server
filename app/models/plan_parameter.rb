class PlanParameter < ActiveRecord::Base
	include Grape::Entity::DSL
  belongs_to :subscription_plan

  attr_accessible :id, :parameter, :value

  entity :id, 
  	:parameter, 
  	:value,
  	:created_at, 
  	:updated_at do
  end
  
  validates :parameter, :allow_nil => false, uniqueness: { case_sensitive: false, scope: :subscription_plan_id  }

end
