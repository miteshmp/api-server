# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_subscription do
    user_id 1
    plan_id "freemium"
    subscription_uuid "xyz123"
    deleted_at "2014-08-15 11:43:20"
    subscription_plan_id 1
    state "active"
  end
end
