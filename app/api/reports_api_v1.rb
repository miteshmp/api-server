require 'grape'
require 'json'

class ReportsAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
  formatter :json, SuccessFormatter
  format :json
  default_format :json
  helpers AuthenticationHelpers
  helpers APIHelpers
  helpers ReportsHelper

  resource :reports do

    # Generate a new Hubble report that gives details on users & devices in the system
    # Needs admin privileges
    params do
      requires :email, :type => String,  :desc => "Report email address"
    end

    post "generate" do
      active_user = authenticated_user
      forbidden_request! unless active_user.has_authorization_to?(:read_any, User)
      report_data = create_user_report()
      msg = "Sent user report!"
      if report_data.empty?
        msg = "Unable to generate report. Try again later"
      else
#        Notifier.user_report(params[:email], report_data).deliver
      end
      status 200
      {
        :email => params[:email],
        :msg => msg
      }
    end
  end

end
