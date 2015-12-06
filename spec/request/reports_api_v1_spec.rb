require "spec_helper"
# require "rack/test"

# API_PATH = "/api/v1/"

# # app method is needed for rack-test
# def app
#   APIServer::Application
# end

# todo:
describe ReportsAPI_v1 do
  
  # before do
  #   Grape::Endpoint.before_each do |endpoint|
  #     endpoint.stub(:ReportsHelper).create_user_report(['desired_value'])
  #   end
  # end


  it "creates a report for given email" do
    get "/reports/ss?api_key=zWRx_gJoB9yxVGmAHGDy"
    # response.body.should == "  "
    expect(response.status).to eq 201
  end

end
