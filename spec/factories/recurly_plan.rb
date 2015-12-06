# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :recurly_plan, class: OpenStruct do
    plan_code "plan1"
    name "plan1"
    plan_interval_length ""
    plan_interval_unit "months"
    unit_amount_in_cents {{ "usd" => 1000 }}
  end
end
