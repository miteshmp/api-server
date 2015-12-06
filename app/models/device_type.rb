class DeviceType < ActiveRecord::Base
  audited
  has_associated_audits
  acts_as_paranoid
  include Grape::Entity::DSL
  serialize :capability, Array
  attr_accessible :type_code, :description, :id, :name, :capability

  self.per_page = Settings.default_page_size

has_many :device_models, :dependent => :destroy

  entity :id,
  :type_code,
  :name,
  :description,
  :capability do 
end


validates :type_code, :allow_nil => false, uniqueness: { case_sensitive: false }, :length => {  :is => 2 }
validates :name, :allow_nil => false, uniqueness: { case_sensitive: false }, :length => { :in => 5..30 }

# allows only alphanumeric with special characters ".","_" and "_" for name and type_code
validates :name, format: { with: /\A[a-zA-Z0-9._-]+\z/,
    message: Settings.invalid_format_message }  
validates :type_code, format: { with: /\A[a-zA-Z0-9_-]+\z/,
    message: Settings.invalid_format_message }    

 end  	
