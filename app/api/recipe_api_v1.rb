require 'grape'
require 'json'


class RecipeAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
  format :json
  version 'v1', :using => :path, :format => :json
  formatter :json, SuccessFormatter

  helpers AwsHelper

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :recipes do

    desc "Add Recipe (needs admin privileges)"
    params do
      requires :program_code, :type => Integer, :desc => "The program code for recipe (must be unique in combination with name)"
      requires :device_model_id, :type => Integer, :desc => "Device's mode id supporting the recipe"
      requires :name, :type => String, :desc => "Recipe name (must be unique in combination with program_code)"
      requires :default_duration, :type => String, :desc => "Recipe's default cooking duration"
      optional :min_duration, :type => String
      optional :max_duration, :type => String
    end
    post 'add' do
      authenticated_user
      device_model = DeviceModel.where(id: params[:device_model_id]).first
      not_found!(TYPE_NOT_FOUND, "DeviceModelId: " + params[:device_model_id].to_s) unless device_model
      forbidden_request! unless current_user.has_authorization_to?(:manage, Recipe)

      recipe = Recipe.new
      recipe.name = params[:name]
      recipe.program_code = params[:program_code]
      recipe.device_model_id = params[:device_model_id]
      recipe.default_duration = params[:default_duration]
      recipe.min_duration = params[:min_duration]
      recipe.max_duration = params[:max_duration]
      recipe.save!

      status 200
      present recipe
    end

    desc "Edit Recipes"
    params do
      optional :program_code, :type => Integer, :desc => "The program code for recipe (must be unique in combination with name)"
      optional :device_model_id, :type => Integer, :desc => "Device's mode id supporting the recipe"
      optional :name, :type => String, :desc => "Recipe name (must be unique in combination with program_code)"
      optional :default_duration, :type => String, :desc => "Recipe's default cooking duration"
      optional :min_duration, :type => String
      optional :max_duration, :type => String
    end
    put ':id' do
      authenticated_user
      if (params[:device_model_id])
        device_model = DeviceModel.where(id: params[:device_model_id]).first
        not_found!(TYPE_NOT_FOUND, "DeviceModelId: " + params[:device_model_id].to_s) unless device_model
      end
      forbidden_request! unless current_user.has_authorization_to?(:manage, Recipe)
      recipe = Recipe.where(id: params[:id]).first()
      not_found!(TYPE_NOT_FOUND, "RecipeId: " + params[:id].to_s) unless recipe

      recipe.name = params[:name] if params[:name]
      recipe.program_code = params[:program_code] if params[:program_code]
      recipe.device_model_id = params[:device_model_id] if params[:device_model_id]
      recipe.default_duration = params[:default_duration] if params[:default_duration]
      recipe.min_duration = params[:min_duration] if params[:min_duration]
      recipe.max_duration = params[:max_duration] if params[:max_duration]
      recipe.save!

      status 200
      recipe
    end

    desc "Delete a Recipe"
    delete ':id' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:manage, Recipe)
      recipe = Recipe.where(id: params[:id]).first()
      not_found!(TYPE_NOT_FOUND, "RecipeId: " + params[:id].to_s) unless recipe
      recipe.destroy
      status 200
      "Recipe deleted!"
    end

    desc "Get default cook programs"
    params do
      optional :page, :type => Integer, default: 1, :desc => "Page number."
      optional :size, :type => Integer, default: 10, :desc => "Number of records per page (defaut 10)."
    end
    get 'default_programs' do
      authenticated_user

      # params[:size] = Settings.default_page_size unless params[:size]
      total_count = Recipe.count()
      recipes = Recipe.order('id ASC').paginate(:page => params[:page], :per_page => params[:size])
      status 200
      {
        :data => recipes,
        :total_count => total_count
      }

    end
  
    desc "Get a list of recipes from the web"
    params do
      optional :q, :type => String, :desc => "Search query for the recipe (eg., slow cooker chicken)"
    end
    get 'list' do
      authenticated_user
      if (params[:q].blank?)
        params[:q] = "slow cooker"
      end
    get_other_recipes(params[:q])
    end

  end

end
