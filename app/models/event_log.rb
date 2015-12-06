class EventLog < ActiveRecord::Base
  
  include Grape::Entity::DSL

  # "attr_accessible"
  attr_accessible :id,
  	:event_name,
  	:event_description,
  	:remote_ip,
  	:registration_id,
  	:user_agent,
  	:time_stamp

  belongs_to :user

  entity :id,
 	:event_name,
 	:event_description,
 	:remote_ip,
 	:registration_id,
 	:user_agent,
 	:time_stamp do
 		expose :user, :using => User::Entity
  end


end
