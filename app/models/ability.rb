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
        can :define_action, User
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
        can :manage, Recipe
        can :read_any, Recipe
        can :read_any, DeviceInvitation
        can :send, DeviceInvitation
        can :read_any, ExtendedAttribute
        can :read_any, MarketingContent
        can :update, DeviceMasterBatch

    elsif user.is? :user

        cannot :read_any, Device
        cannot :read_any, User
        cannot :read_any, UserSubscription       
        can :read_any, Recipe
        can :create, UserSubscription
        can :read_any, SubscriptionPlan
        can :update, UserSubscription do |user_subscription|
            user_subscription.try(:user) == user
        end 
        can :list, UserSubscription do |user_subscription|
            user_subscription.try(:user) == user
        end
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
        can :create_talkback_session, Device do |device|
            device.try(:user) == user
        end
        can :delete_event, Device do |device|
            device.try(:user) == user
        end

    elsif user.is? :wowza_user
        can :close_session, Device
        can :validate_stream, Device

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
       can :update, DeviceFreeTrial 

    elsif user.is? :talk_back_user 
       can :start_audio_session, RelaySession
       can :stop_audio_session, RelaySession

    elsif user.is? :upload_server
        can :read_any, User
        can :read_any, Device

    elsif user.is? :marketing_admin
        can :read_any, MarketingContent
        can :create, MarketingContent
        can :manage, SubscriptionPlan
    end
    
  end
  
end
