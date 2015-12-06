# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :background_job do
    local_ip_address 1
    total_job_time 1
  end
end
