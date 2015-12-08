class DeviceModelCapability < ActiveRecord::Base
	include Grape::Entity::DSL
	serialize :capability, Array
    attr_accessible :capability, :firmware_prefix

    belongs_to :device_model

    entity :id,
	  :firmware_prefix,
	  :capability do 
	end

	validates :firmware_prefix, :allow_nil => false, uniqueness: { case_sensitive: false, scope: :device_model_id }
	validates :firmware_prefix, format: { with: /\A\d+.\d+\z/,
    message: "Has invalid format.It should be in format xx.yy" }  
end
