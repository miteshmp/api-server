require 'spec_helper'

describe Pet do
  it { should validate_presence_of :name } 
  it { should belong_to :user }
  
  context "Entity" do  
    it "should have an entity that returns expected keys" do
      Pet::Entity.exposures.keys.should include :name, :id
    end
  
    it "should have an entity produces JSON" do
      pet = Pet.create(name: "fifi")
      
      pet_json = JSON.parse((Pet::Entity.represent [pet]).to_json).first
      pet_json['name'].should == "fifi"
      pet_json['id'].should == pet.id
    end
  end
end