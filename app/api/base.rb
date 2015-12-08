require 'grape'
require 'grape-swagger'
require 'error_format_helpers'
require 'error_codes'
require 'new_relic/agent/instrumentation/rack'

class Base < Grape::API
  format :json
  default_format :json

  rescue_from Grape::Exceptions::Validation do |e|
    Rack::Response.new({
      :status => e.status,
      :code => ERROR_GENERAL_VALIDATION,
      :message => e.message,
      :more_info => Settings.error_docs_url %  ERROR_GENERAL_VALIDATION,
      :back_trace => e.backtrace
      }.to_json,  e.status, { "Content-type" => "application/json" })
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      Rack::Response.new({
        :status => 422,
        :code => ERROR_ACTIVE_RECORD,
        :message => e.message,
        :more_info => Settings.error_docs_url %  ERROR_ACTIVE_RECORD
        }.to_json,  422, { "Content-type" => "application/json" })
      end

    rescue_from ActiveRecord::RecordNotFound do |e|
      Rack::Response.new({
        :status => 422,
        :code => ERROR_ACTIVE_RECORD,
        :message => e.message,
        :more_info => Settings.error_docs_url %  ERROR_ACTIVE_RECORD
        }.to_json,  422, { "Content-type" => "application/json" })
      end  

    rescue_from ActiveRecord::StatementInvalid do |e|
      Rack::Response.new({
        :status => 500,
        :code => ERROR_ACTIVE_RECORD,
        :message => e.message,
        :more_info => Settings.error_docs_url %  ERROR_ACTIVE_RECORD,
        :back_trace => e.backtrace
        }.to_json,  500, { "Content-type" => "application/json" })
      end 

    rescue_from Timeout::Error do |e|
      Rack::Response.new({
        :status => 500,
        :code => TIMEOUT_ERROR,
        :message => e.message,
        :more_info => Settings.error_docs_url %  TIMEOUT_ERROR,
        :back_trace => e.backtrace
        }.to_json,  500, { "Content-type" => "application/json" })
      end  

      rescue_from TypeError do |e|
      Rack::Response.new({
        :status => 500,
        :code => TYPE_ERROR,
        :message => "Parameters passed are not proper",
        :more_info => Settings.error_docs_url %  TYPE_ERROR,
        }.to_json,  500, { "Content-type" => "application/json" })
      end  

      rescue_from :all do |e|
          Rack::Response.new({
              :status => 500,
              :code => UNHANDLED_EXCEPTION,
              :message => e.message,
              :more_info => Settings.error_docs_url %  UNHANDLED_EXCEPTION
              }.to_json,  400, { "Content-type" => "application/json" })
      end


      # Import any helpers that we need
      helpers APIHelpers
      helpers AuthenticationHelpers
      helpers ApiPageHelper
      helpers StunHelper

      # mount the APIs that we want to expose

     
      mount Base1
      mount Base2
   
      
      if Rails.env.production?
        extend NewRelic::Agent::Instrumentation::Rack
      end
    end

