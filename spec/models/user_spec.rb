require 'spec_helper'

describe User do

  it "has a valid factory" do
    FactoryGirl.build_stubbed(:user).should be_valid
  end

  it "should not be valid without a name" do
    user = FactoryGirl.build_stubbed(:user, :name=>"")
    user.should_not be_valid
  end

  it "should not be valid without an email" do
    user = FactoryGirl.build_stubbed(:user, :email=>"")
    user.should_not be_valid
  end

  it "should not be valid without a password" do
    user = FactoryGirl.build_stubbed(:user, :password=>"")
    user.should_not be_valid
  end

  it "should not be valid with password length less than 8" do
    user = FactoryGirl.build_stubbed(:user, :password=>"123", :password_confirmation=>"123")
    user.should_not be_valid
  end

  it "should not be valid without a different confirmation password" do
    user = FactoryGirl.build_stubbed(:user, :password_confirmation=>"")
    user.should_not be_valid
  end

  it "should not be valid with an invalid email" do
    user = FactoryGirl.build_stubbed(:user, :email=>"notemail@email")
    user.should_not be_valid
    user = FactoryGirl.build_stubbed(:user, :email=>"notemail")
    user.should_not be_valid
    user = FactoryGirl.build_stubbed(:user, :email=>"notemail@email.n")
    user.should_not be_valid
  end

  it "should not be valid with an invalid name" do
    user = FactoryGirl.build_stubbed(:user, :name=>"hello user")
    user.should_not be_valid
    user = FactoryGirl.build_stubbed(:user, :name=>"hello&^%user")
    user.should_not be_valid
    user = FactoryGirl.build_stubbed(:user, :name=>"he")
    user.should_not be_valid
  end
end
