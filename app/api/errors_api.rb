require 'grape'
require 'json'

class ErrorsAPI < Grape::API
  resource :errors do
    desc ""
    get "3001"  do

      "Invalid parameter can be caused by the following..."
    end
  end
end