FactoryGirl.define do
  factory :user do |f|
    name { Faker::Name.first_name }
    email { Faker::Internet.email }
    password { Faker::Internet.password(8) }
    password_confirmation {|u| u.password}
  end
end
