# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :device_free_trial do
    device_id 1
    user_id 1
    plan_id "MyString"
  end
end
