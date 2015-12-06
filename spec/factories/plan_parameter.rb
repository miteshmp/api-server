FactoryGirl.define do
  factory :plan_parameter do
    parameter "some_parameter"
    value "value"
    subscription_plan_id "1"
  end
end
