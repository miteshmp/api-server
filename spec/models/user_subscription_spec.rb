require 'spec_helper'

describe UserSubscription do

  it "has a valid factory" do
    FactoryGirl.create(:subscription_plan)
    FactoryGirl.create(:user_subscription).should be_valid
  end

  it "is invalid without a subscription_uuid" do
    FactoryGirl.create(:subscription_plan)
    FactoryGirl.build(:user_subscription, :subscription_uuid => nil).should_not be_valid
  end

  it "is invalid without a subscription plan" do
    FactoryGirl.build(:user_subscription).should_not be_valid
  end


  context "recurly subscription" do

    it "creates a subscription for valid inputs" do
      FactoryGirl.create(:subscription_plan, :id => 1)
      user_subscription = FactoryGirl.build(:user_subscription)
      fake_subscription = FactoryGirl.build(:recurly_subscription)
      Recurly::Subscription.stub(:create) do |*args|
        fake_subscription
      end
      user_subscription.create_recurly_subscription("somesecret", "USD").should eq(fake_subscription)
    end

    it "reactivates a subscription for valid inputs" do
      FactoryGirl.create(:subscription_plan, :id => 1)
      user_subscription = FactoryGirl.build(:user_subscription, :state => "canceled")
      fake_subscription = FactoryGirl.build(:recurly_subscription, :state => "active")
      def fake_subscription.reactivate(*args)
        fake_subscription
      end
      Recurly::Subscription.stub(:find) do |*args|
        fake_subscription
      end
      user_subscription.reactivate_recurly_subscription(user_subscription.subscription_uuid).should eq(fake_subscription)
      user_subscription.state.should eq("active")
    end

    it "changes a recurly subscription for valid inputs" do
      user_subscription = FactoryGirl.build(:user_subscription)
      fake_subscription = FactoryGirl.build(:recurly_subscription, :state => "active")
      def fake_subscription.update_attributes(*args)
        fake_subscription
      end
      Recurly::Subscription.stub(:find) do |*args|
        fake_subscription
      end
      plan = FactoryGirl.create(:subscription_plan)
      user_subscription.change_recurly_subscription(plan, false).should eq(fake_subscription)
    end

    it "cancels a recurly subscription for valid inputs" do
      user_subscription = FactoryGirl.build(:user_subscription)
      fake_subscription = FactoryGirl.build(:recurly_subscription, :state => "canceled")
      def fake_subscription.cancel(*args)
        fake_subscription
      end
      Recurly::Subscription.stub(:find) do |*args|
        fake_subscription
      end
      plan = FactoryGirl.create(:subscription_plan)
      user_subscription.change_recurly_subscription(plan, true).should eq(fake_subscription)
    end

    it "raises an error when a recurly account is not found" do
      user_subscription = FactoryGirl.build(:user_subscription)
      fake_subscription = FactoryGirl.build(:recurly_subscription, :errors => {"account" => ["some error1", "some error2"]})
      Recurly::Subscription.stub(:create) do |*args|
        fake_subscription
      end
      expect { user_subscription.create_recurly_subscription("somesecret", "USD") }.to raise_error(RuntimeError, "Recurly error! [account] some error1, some error2! ")
    end

    it "raises an error when a recurly subscription doesn't get created" do
      user_subscription = FactoryGirl.build(:user_subscription)
      fake_subscription = FactoryGirl.build(:recurly_subscription, :errors => {"new_plan" => ["iamerror"]})
      Recurly::Subscription.stub(:create) do |*args|
        fake_subscription
      end
      expect { user_subscription.create_recurly_subscription("somesecret", "USD") }.to raise_error(RuntimeError, "Recurly error! [new_plan] iamerror! ")
    end

  end

end
