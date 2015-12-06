class Recipe < ActiveRecord::Base
  acts_as_paranoid
  include Grape::Entity::DSL

  belongs_to :device_model

  attr_accessible :default_duration, 
  :device_model_id, 
  :max_duration, 
  :min_duration, 
  :name, 
  :program_code
  
  entity :default_duration, 
  :device_model_id, 
  :max_duration, 
  :min_duration, 
  :name, 
  :program_code do
  end

  validates_uniqueness_of :name, :scope => :program_code, :allow_nil => false, :case_sensitive => false
  validate :device_model_must_be_in_the_list	

  def device_model_must_be_in_the_list
	unless  DeviceModel.where(id: device_model_id).first
	  errors.add(:device_model_id, "'%s' is invalid." % device_model_id)
	end
  end
end
