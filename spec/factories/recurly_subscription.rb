# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :recurly_subscription, class: OpenStruct do
    uuid "xyz123"
    state "freemium"
    current_period_ends_at "2014-08-15 11:43:20"
    errors nil
    unit_amount_in_cents 199
  end
end
