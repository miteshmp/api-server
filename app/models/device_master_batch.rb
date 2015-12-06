class DeviceMasterBatch < ActiveRecord::Base
	stampable
	include Grape::Entity::DSL
  	attr_accessible :file_name
  	attr_accessor :creator

  	has_many :device_master, :dependent => :destroy
  	belongs_to :device_model

  	 entity :id,
	  :file_name,
	  :creator,
	  :created_at,
      :updated_at do 
	  end

	  validates :file_name, :allow_nil => false, uniqueness: { case_sensitive: false }

	 
end
