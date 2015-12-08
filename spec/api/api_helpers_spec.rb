require "spec_helper"
require "rack/test"

# app method is needed for rack-test
def app
  APIServer::Application
end

## This could be the start of Grape::Test
# we create a mock API object that uses Rack::Test to stub out a mock request and response.
def api
  api_double = double('api')
  api_double.stub(:request) do  
    last_request
  end
  api_double.stub(:response) do 
    last_response
  end
  api_double.stub(:env) do 
    last_request.env
  end
  api_double.extend Base.helpers
end

describe "Grape Demp API Helpers" do
  include Rack::Test::Methods

  before(:each) do
    @api = api  
  end
    
  it "should call error from bad request" do
    @api.should_receive(:error!).with("Bad Request", 400)
    @api.bad_request!
  end

  it "should call error from access denied" do
    @api.should_receive(:error!).with("Access Denied", 401)
    @api.access_denied!
  end
  
  it "should call error from bad request" do
    @api.should_receive(:error!).with("Forbidden", 403)
    @api.forbidden_request!
  end
    
  it "should call error from bad request" do
    @api.should_receive(:error!).with("Not Found", 404)
    @api.not_found!
  end
  
  it "should call error from bad request" do
    @api.should_receive(:error!).with("WAT!", 422)
    @api.invalid_request!("WAT!")
  end
end
