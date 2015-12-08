class Plan < ActiveRecord::Base
   include Grape::Entity::DSL
  
  has_many :device_plans
  
  attr_accessible :description, :id, :name
  
  entity :id, :name, :description, :created_at, :updated_at do
  end
  
end
