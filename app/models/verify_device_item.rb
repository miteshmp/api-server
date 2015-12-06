class VerifyDeviceItem
	include Grape::Entity::DSL
attr_accessor :registration_id, :is_valid, :messages

def persisted?
	false
end	

def initialize
     self.messages = [] # on object creation initialize this to an array
end

entity :registration_id,
  :is_valid,
  :messages do
  end

end