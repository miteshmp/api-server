require 'spec_helper'

describe Device do

  context "subscriptions" do
    let!(:device_model) { FactoryGirl.create(:device_model) }
    let!(:device) { FactoryGirl.create(:device, :user_id => 1, :registration_id => "12345678") }
    let!(:subscription_plan) do
      FactoryGirl.create(:subscription_plan, :id => 1)
      FactoryGirl.create(:subscription_plan, :id => 2, :plan_id => "tier1")
    end
    let!(:user_subscription) { FactoryGirl.create(:user_subscription, :user_id => 1, :subscription_plan_id => 1) }

    context "for valid inputs" do
      let!(:plan_parameter) { FactoryGirl.create(:plan_parameter, :parameter => PLAN_PARAMETER_MAX_DEVICES_FIELD, :value => "4", :subscription_plan_id => 2) }
      let!(:user_subscription) { FactoryGirl.create(:user_subscription, :user_id => 1, :subscription_plan_id => 2,  :plan_id => "tier1") }
      
      it "return subscription information of devices" do
        some_user = FactoryGirl.create(:user, :id => 1)
        current = Device.get_subscriptions(some_user)
        current[:plan_device_availability].should eq({"tier1"=>4})
      end

      it "changes subscription of devices" do
        some_user = FactoryGirl.create(:user, :id => 1)
        Device.change_subscriptions("freemium", [12345678], some_user).should eq(1)
      end

      it "applies subscription to devices" do
        some_user = FactoryGirl.create(:user, :id => 1)
        Device.apply_subscriptions(some_user, "tier1", [12345678]).should eq(1)
      end
    end

    context "for invalid inputs" do
      let!(:plan_parameter) { FactoryGirl.create(:plan_parameter, :parameter => PLAN_PARAMETER_MAX_DEVICES_FIELD, :value => "0", :subscription_plan_id => 2) }

      it "raises exception when subscription for plan does not exist" do
        some_user = FactoryGirl.create(:user, :id => 1)
        FactoryGirl.build(:user_subscription, :user_id => 1, :subscription_plan_id => 2, :plan_id => "tier1", :state => "expired")
        expect { Device.apply_subscriptions(some_user, "tiersomething", [12345678]) }.to raise_error(StandardError, "No active subscription found for tiersomething!")
        expect { Device.apply_subscriptions(some_user, "tier1", [12345678]) }.to raise_error(StandardError, "No active subscription found for tier1!")
      end

      it "raises exception when device count is reached for a plan" do
        some_user = FactoryGirl.create(:user, :id => 1)
        FactoryGirl.create(:user_subscription, :user_id => 1, :subscription_plan_id => 2, :plan_id => "tier1")
        expect { Device.apply_subscriptions(some_user, "tier1", [12345678]) }.to raise_error(StandardError, "Available devices for tier1: 0")
      end

      it "raises exception when it encounters an invalid device registration_id" do
        some_user = FactoryGirl.create(:user, :id => 1)
        FactoryGirl.create(:subscription_plan, :id => 3, :plan_id => "tier2")
        FactoryGirl.create(:plan_parameter, :parameter => PLAN_PARAMETER_MAX_DEVICES_FIELD, :value => "4", :subscription_plan_id => 3)
        FactoryGirl.create(:user_subscription, :user_id => 1, :subscription_plan_id => 3, :plan_id => "tier2")
        expect { Device.apply_subscriptions(some_user, "tier2", [33]) }.to raise_error(StandardError, "Invalid device registration_id found in: 33")
      end
    end

  end

end
