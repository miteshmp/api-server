class DeviceModel < ActiveRecord::Base
  acts_as_paranoid
  audited :associated_with => :device_type
	include Grape::Entity::DSL

  extend Enumerize
  attr_accessible :model_no, :description, :id, :name, :udid_scheme
  self.per_page = Settings.default_page_size

  
has_many :action_configs, :dependent => :destroy
has_many :devices, :dependent => :destroy
has_many :device_model_capabilities, :dependent => :destroy
has_many :device_master_batches, :dependent => :destroy
has_many :recipes, :dependent => :destroy
belongs_to :device_type

enumerize :udid_scheme, :in => { physical: 1, virtual: 2, donotcheck: 0 }, :default => :physical, :scope =>  :having_udid_schemes

  entity :id,
  :tenant_id,  
  :model_no,
  :name,
  :description,
  :udid_scheme do 
    expose :device_model_capabilities, :using => DeviceModelCapability::Entity
end


validates :model_no, :allow_nil => false, uniqueness: { case_sensitive: false }, :length => {  :is => 4}
validates :name, :allow_nil => false, uniqueness: { case_sensitive: false }, :length => { :in => 5..30 }

# allows only alphanumeric with special characters _" and "_" for model_no
validates :name, format: { with: /\A[a-zA-Z0-9._-]+\z/,
    message: Settings.invalid_format_message }  
validates :model_no, format: { with: /\A[a-zA-Z0-9_-]+\z/,
    message: Settings.invalid_format_message }    



end
