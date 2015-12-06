FactoryGirl.define do
  factory :admin do
  	name "admin"
    email "abc@abc.com"
    password "foobar"
    password_confirmation {|u| u.password}
  end
end