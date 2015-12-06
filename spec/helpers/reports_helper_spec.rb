require 'spec_helper'

describe ReportsHelper do

  context '1, 2 and more than 2 devices' do
    let!(:user) { FactoryGirl.create_list(:user, 8) }
    let!(:device_model) { FactoryGirl.create(:device_model) }
    let!(:device) { FactoryGirl.create(:device, :user_id => 3)
                    FactoryGirl.create(:device, :user_id => 3)
                    FactoryGirl.create(:device, :user_id => 1)
                    FactoryGirl.create_list(:device, 5) }
    it "generates report list" do
      data = helper.create_user_report()
      expected = [{"name"=>"Total Hubble users", "count"=>8}, {"name"=>"Total users registered this month", "count"=>8}, {"name"=>"Total devices registered with Hubble", "count"=>8}, {"name"=>"Total devices registered this month", "count"=>8}, {"name"=>"Total users with 1 device", "count"=>1}, {"name"=>"Total users with 2 device", "count"=>1}, {"name"=>"Total users with more than 2 devices", "count"=>1}]
      data.size.should == 7
      data.should =~ expected
    end
  end

  context '1, 2 devices' do
    let!(:user) { FactoryGirl.create_list(:user, 8) }
    let!(:device_model) { FactoryGirl.create(:device_model) }
    let!(:device) { FactoryGirl.create(:device, :user_id => 3)
                    FactoryGirl.create(:device, :user_id => 3)
                    FactoryGirl.create(:device, :user_id => 1) }
    it "generates report list" do
      data = helper.create_user_report()
      expected = [{"name"=>"Total Hubble users", "count"=>8}, {"name"=>"Total users registered this month", "count"=>8}, {"name"=>"Total devices registered with Hubble", "count"=>3}, {"name"=>"Total devices registered this month", "count"=>3}, {"name"=>"Total users with 1 device", "count"=>1}, {"name"=>"Total users with 2 device", "count"=>1}]
      data.size.should == 6
      data.should =~ expected
    end
  end

  it "returns a proper report when there is no data" do
    data = helper.create_user_report()
    expected = [{"name"=>"Total Hubble users", "count"=>0}, {"name"=>"Total users registered this month", "count"=>0}, {"name"=>"Total devices registered with Hubble", "count"=>0}, {"name"=>"Total devices registered this month", "count"=>0}]
    data.size.should == 4
  end

end
