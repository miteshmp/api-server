class Ability
  include CanCan::Ability

  def initialize(user)

     user ||= User.new # guest user

    if user.is? :admin

        can :manage, :all
        can :read_any_user, User
        can :read_any, User
        can :read_any, Device
        can :change_role, User
        can :read_any, DeviceType
        can :read_any, DeviceModel
        can :deactivate, Device
        can :check_high_usage, Device
        can :read_any, SubscriptionPlan
        can :read_any, PlanParameter
        can :read_any, DeviceMasterBatch
        can :read_any, DeviceMaster
        can :read_any, DeviceModelCapability
        can :read_any, ApiCallIssues
        can :read_any, DeviceInvitation
        can :send, DeviceInvitation

    elsif user.role == "admin"
       can :change_role, User     

    elsif user.is? :user

        cannot :read_any, Device
        cannot :read_any, User       
        can :create, Device
        can :update, Device do |device|
            device.try(:user) == user
        end
        
        can :destroy, Device do |device|
            device.try(:user) == user
        end
        
        can :list_recorded_files, Device do |device|
            device.try(:user) == user
        end
        
        can :list, Device do |device|
            device.try(:user) == user
        end
        can :send_command, Device do |device|
            device.try(:user) == user
        end
        can :create_session, Device do |device|
            device.try(:user) == user
        end
        can :cancel_subscription, Device do |device|
            device.try(:user) == user
        end
        can :list, DeviceModelCapability do |device_model_capability|
            device_model_capability.try(:user) == user
        end
        can :share, Device do |device|
            device.try(:user) == user
        end
        can :accept, DeviceInvitation

    elsif user.is? :wowza_user
        can :close_session, Device

    elsif user.is? :factory_user
        can :create, DeviceMasterBatch
        can :get_logs, Device
        can :read_any, DeviceMasterBatch

    elsif user.is? :helpdesk_agent
       can :read_any, User
       can :read_any, Device 
       can :destroy, User

    elsif user.is? :tester 
       can :read_any, User
       can :read_any, Device 
       can :read_any, App 

    elsif user.is? :bp_server 
       can :deactivate, Device
       can :check_high_usage, Device
       can :delete_s3_events, Device  

      
    end
    
  end
  
end
