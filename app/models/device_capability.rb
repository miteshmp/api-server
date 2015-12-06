class DeviceCapability < ActiveRecord::Base
  include Grape::Entity::DSL

  serialize :value, HashSerializer.new

  attr_accessible :device_id, :value

  belongs_to :device

  entity :device_id, :value do
  end
end

