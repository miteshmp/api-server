# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*' # allow all the domains
    resource '*', 
      headers: :any, 
      :methods => [:get, :post, :put, :delete, :options]
  end
end

NewRelic::Agent.manual_start

run APIServer::Application
