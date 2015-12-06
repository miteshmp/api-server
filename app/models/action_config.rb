class ActionConfig < ActiveRecord::Base
	include Grape::Entity::DSL
  	
  	attr_accessible :action_name, :action_value, :action_rule
  	
	validates :action_name,  :allow_nil => false,presence: true
	validates :action_value, :allow_nil => false,presence: true

	belongs_to :device_models

  	entity :action_name,
	  :action_value,
	  :action_rule do
	  	expose :created_at, if: { type: :full }
    	expose :updated_at, if: { type: :full }
	  end
end