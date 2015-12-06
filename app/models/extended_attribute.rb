class ExtendedAttribute < ActiveRecord::Base
  include APIHelpers
  include Grape::Entity::DSL
  audited	

  self.per_page = Settings.default_page_size
  attr_accessible :key, :entity_id, :entity_type, :value
  belongs_to :entity, polymorphic: true

  belongs_to :device, foreign_key: 'entity_id'

  entity :id, 
  :entity_id, 
  :entity_type,
  :key,
  :value,
  :updated_at do
    expose :device, :using => Device::Entity, if: { type: :device } 
  end

  validates_uniqueness_of :key, :scope => [:entity_id, :entity_type]
  validates :key, :length => { :in => 1..25 } 

  def device_attribute_set_by_device(user,device,key,value)

    self.key = key
    self.value = value
    self.save!

    Thread.new {

      ThreadUtility.with_connection do

        # verify that attribute part of push notification
        if EXTENDED_ATTRIBUTE_TO_APP.include? key
          # send push notification
        end

      end
    }

  end

  def device_attribute_set_by_user(key,value)

  	self.key = key
    self.value = value
    self.save!

  end


  def self.invalid_key(key)
  	key.include? ","
  end	

end

