FactoryGirl.define do
  factory :device_model do |f|
    model_no Faker::Number.number(4)
    description Faker::Lorem.word
    name Faker::Lorem.characters(5)
    id "1"
  end
end