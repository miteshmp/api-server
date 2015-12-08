class SharedDevice < ActiveRecord::Base
	include Grape::Entity::DSL
	belongs_to :device
  belongs_to :primary_user, :class_name => 'User', :foreign_key => 'shared_by'
  belongs_to :secondary_user, :class_name => 'User', :foreign_key => 'shared_with'

  
  	attr_accessible :id, :shared_by, :shared_with
  	entity :id,
  	:shared_by,
  	:shared_with,
  	:created_at,
    :updated_at do
      expose :device, :using => Device::Entity
      expose :primary_user,:using => User::Entity
      expose :secondary_user,:using => User::Entity
  end

  validates_uniqueness_of :device_id, :scope => [:shared_by, :shared_with]
end
