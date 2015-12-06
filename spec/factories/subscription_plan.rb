# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription_plan do
    plan_id "freemium"
    price_cents "0"
    currency_unit "USD"
    renewal_period_month 1
  end
end
