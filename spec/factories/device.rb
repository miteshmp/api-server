FactoryGirl.define do
  factory :device do |f|
    f.name { Faker::Lorem.characters(6) }
    f.registration_id { Faker::Number.number(26) }
    f.mac_address { Faker::Internet.mac_address.gsub(":", "") }
    f.auth_token Faker::Internet.password(16)
    f.user_id Faker::Number.digit
    f.time_zone Faker::Number.digit
    f.plan_id "freemium"
    f.device_model_id "1"
    f.created_at "NOW()"
    f.updated_at "NOW()"
    f.firmware_version "1.0.0"
  end
end