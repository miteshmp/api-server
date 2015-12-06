require 'spec_helper'

describe SubscriptionPlan do

  it "has a valid factory" do
    FactoryGirl.create(:subscription_plan).should be_valid
  end

  it "is invalid for duplicate plan_id" do
    FactoryGirl.create(:subscription_plan)
    FactoryGirl.build(:subscription_plan).should_not be_valid
  end

  it "is invalid for out of bound price amount" do
    FactoryGirl.build(:subscription_plan, :price_cents => 110000).should_not be_valid
    FactoryGirl.build(:subscription_plan, :price_cents => -1).should_not be_valid
  end

  it "is invalid for out of bound renewal period" do
    FactoryGirl.build(:subscription_plan, :renewal_period_month => 13).should_not be_valid
    FactoryGirl.build(:subscription_plan, :renewal_period_month => -1).should_not be_valid
  end

  it "is invalid when plan name has special characters" do
    FactoryGirl.build(:subscription_plan, :plan_id => "i!msp*cial").should_not be_valid
  end

  context "recurly" do
    it "should create plan for valid input" do
      subscription_plan = SubscriptionPlan.new
      fake_plan =
      Recurly::Plan.stub(:create) do |*args|
        FactoryGirl.build(:recurly_plan, :plan_code => args[0], :name => args[0], :unit_amount_in_cents => args[1])
      end
      subscription_plan = subscription_plan.create_recurly_plan("myplan", 3000, "USD", 1)
      subscription_plan.plan_id.should eq("myplan")
      subscription_plan.price_cents.should eq(3000)
      subscription_plan.currency_unit.should eq("USD")
    end

    it "should delete a plan for valid input" do
      subscription_plan = FactoryGirl.create(:subscription_plan)
      fake_plan = FactoryGirl.build(:recurly_plan)
      def fake_plan.destroy
      end
      Recurly::Plan.stub(:find) do |*args|
        fake_plan
      end
      expect { subscription_plan.delete_recurly_plan }.to change(SubscriptionPlan, :count). by(-1)
    end

    it "should update a plan for valid input" do
      subscription_plan = FactoryGirl.create(:subscription_plan)
      fake_plan = FactoryGirl.build(:recurly_plan)
      def fake_plan.save
      end
      Recurly::Plan.stub(:find) do |*args|
        fake_plan
      end
      subscription_plan.update_recurly_plan(300)
      subscription_plan.price_cents.should eq(300)
    end

    it "should raise exception for unknown errors" do
      subscription_plan = FactoryGirl.create(:subscription_plan)
      fake_plan = FactoryGirl.build(:recurly_plan, :errors => {"plan_code" => ["has already been taken"]})
      def fake_plan.save
      end
      Recurly::Plan.stub(:find) do |*args|
        fake_plan
      end
      expect { subscription_plan.update_recurly_plan(300) }.to raise_error(RuntimeError, "Recurly error! [plan_code] has already been taken! ")
    end
  end

end
