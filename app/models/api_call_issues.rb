class ApiCallIssues < ActiveRecord::Base
  include Grape::Entity::DSL
  attr_accessible :api_type, :count, :error_data, :error_reason

  entity :id,
  :api_type,
  :count,
  :error_data,
  :error_reason do
  end

end
