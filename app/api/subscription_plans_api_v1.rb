class SubscriptionPlansAPI_v1 < Grape::API
	version 'v1', :using => :path,  :format => :json
  	format :json
  	formatter :json, SuccessFormatter  	 

	helpers RecurlyHelper

	resource :subscription_plans do

    desc "Create a subscription plan"
    params do
      requires :plan_id, :type => String, :desc => "Name of the plan"
      requires :charge, :type => Integer, :desc => "Charge in USD"
    end  
    post 'create' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:create, SubscriptionPlan)
      plan = SubscriptionPlan.new
      plan.plan_id = params[:plan_id]
      plan.save!

      response = Recurly::Plan.create(
      :plan_code            => params[:plan_id],
      :name                 => params[:plan_id],
      :unit_amount_in_cents => { 'USD' => params[:charge]}
    )
      
      status 200

      present plan, with: SubscriptionPlan::Entity
    end

    desc "Add plan parameter"  
    params do 
      requires :parameter
      requires :value
    end 
    post ':id/plan_parameter' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:create, PlanParameter)

      plan = SubscriptionPlan.where(id: params[:id]).first
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:id].to_s) unless plan

      plan_parameter = plan.plan_parameters.new
      plan_parameter.parameter = params[:parameter]
      plan_parameter.value = params[:value]
      plan.save!



      status 200
      present plan, with: SubscriptionPlan::Entity

    end

    desc "Get list of all subscription plans"
    params do
      optional :page, :type => Integer
      optional :offset, :type => Integer
      optional :size, :type => Integer
    end
    get  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:create, SubscriptionPlan)
     
      status 200

      
      present paginate(SubscriptionPlan.all), with: SubscriptionPlan::Entity
    end  

    desc "Delete a specific subscription_plan"
   
    delete ':id'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:destroy, SubscriptionPlan)
     
      status 200

      subscription_plan = SubscriptionPlan.where(id: params[:id]).first
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:id].to_s) unless subscription_plan


      plan = Recurly::Plan.find(subscription_plan.plan_id)
      plan.destroy
      subscription_plan.destroy
      
    end 

    desc "Update a subscription plan"
    params do
      requires :charge, :type => Integer, :desc => "Charge in USD"
    end  
    put ':id/update' do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:update, SubscriptionPlan)
      
      subscription_plan = SubscriptionPlan.where(id: params[:id]).first
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:id].to_s) unless subscription_plan

      status 200
      plan = Recurly::Plan.find(subscription_plan.plan_id)

      plan.unit_amount_in_cents['USD'] = params[:charge]
      plan.save
      
      plan

      
    end
        

	end	
end	