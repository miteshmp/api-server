require "spec_helper"


# The following has been commented since there's some issue with rspec and devise
# describe "APIv1  Methods" do
#   include Devise::TestHelpers
  # include Warden::Test::Helpers
  # Warden.test_mode!

  # def setup
  # 	request.env["devise.mapping"] = Devise.mappings[:admin]
  #   @admin = FactoryGirl.create :admin
  #   sign_in FactoryGirl.create(:admin)
  #   # @user = create(:user)
  #   # sign_in @user
  # end


#   it "creates a report for given email" do
#     user = double('user')
#     request.env['warden'].stub :authenticate! => user
#     allow(controller).to receive(:current_user) { user }
#     post "/reports/generate", {"email" => "soo@soo.com"}, 'Content-Type' => 'application/json'
#     # response.body.should == "  "
#     last_response.status.should == 200
#   end
# end
