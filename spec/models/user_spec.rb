require 'spec_helper'

describe User do
  it { should validate_uniqueness_of :email }
  it { should validate_presence_of :email }
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }
  
  it { should have_many :pets }
  
  it "should have a name that is their first and last name" do
    user = User.new(:first_name => "Mark", :last_name => "Madsen")
    user.name.should == "Mark Madsen"
  end
  
  context "Entity" do  
    it "should have an entity that returns expected keys" do
      User::Entity.exposures.keys.should include :name, :email, :pets
    end
  
    it "should have an entity produces JSON" do
      user = User.create(first_name: "Mark", last_name: "Madsen", email: "mark@example.com", password: "password")
      pet = Pet.create(name: "fifi", user: user)
      
      user_json = JSON.parse((User::Entity.represent [user]).to_json).first
      user_json['name'].should == "Mark Madsen"
      user_json['email'].should == "mark@example.com"
      user_json['pets'].to_json.should == Pet::Entity.represent([pet]).to_json
      user_json['password'].should be nil
    end
  end
end
