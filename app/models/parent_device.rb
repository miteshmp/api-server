class ParentDevice < Grape:: Entity
attr_accessor :id, :name, :registration_id

 expose :id
 expose :name
 expose :registration_id

def persisted?
	false
end	


end