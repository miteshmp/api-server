class SubscriptionPlansAPI_v1 < Grape::API
  version 'v1', :using => :path,  :format => :json
  format :json
  formatter :json, SuccessFormatter

  resource :subscription_plans do

    desc "Get list of all subscription plans"
    params do
      optional :q, :type => Hash, :desc => "Search parameter"
      optional :page, :type => Integer
      optional :size, :type => Integer
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    get  do
      auth_user = authenticated_user
      forbidden_request! unless auth_user.has_authorization_to?(:read_any, SubscriptionPlan)
      search_result = SubscriptionPlan.search(params[:q])
      plans = params[:q] ? search_result.result(distinct: true) : SubscriptionPlan
      status 200
      present plans.paginate(:page => params[:page], :per_page => params[:size]) , with: SubscriptionPlan::Entity
    end

    desc "Create a subscription plan"
    params do
      requires :plan_id, :type => String, :desc => "Name of the plan"
      requires :plan_price_cents, :type => Integer, :desc => "Plan price"
      optional :currency_unit, :type => String, default: "USD", :desc => "ISO currency. Default is USD"
      optional :renewal_period_month, :type => Integer, default: 1, :desc => "The renewal period for the plan in months. The default value is 1."
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    post 'create' do
      auth_user = authenticated_user
      forbidden_request! unless auth_user.has_authorization_to?(:create, SubscriptionPlan)
      plan = SubscriptionPlan.new
      plan.create_recurly_plan(params[:plan_id], params[:plan_price_cents], params[:currency_unit], params[:renewal_period_month],params[:tenant_id])
      status 200
      present plan, with: SubscriptionPlan::Entity
    end

    desc "Add plan parameter"
    params do
      requires :parameter
      requires :value
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    post ':id/plan_parameter' do
      auth_user = authenticated_user
      forbidden_request! unless auth_user.has_authorization_to?(:create, PlanParameter)
      plan = SubscriptionPlan.where(id: params[:id]).first
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:id].to_s) unless plan
      plan_parameter = plan.plan_parameters.new
      plan_parameter.parameter = params[:parameter]
      plan_parameter.value = params[:value]
      plan_parameter.save!
      status 200
      present plan, with: SubscriptionPlan::Entity
    end

    desc "Update a subscription plan"
    params do
      requires :charge, :type => Integer, :desc => "Charge in USD"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
    end
    put ':id/update' do
      auth_user = authenticated_user
      forbidden_request! unless auth_user.has_authorization_to?(:update, SubscriptionPlan)
      subscription_plan = SubscriptionPlan.where(id: params[:id]).first
      not_found!(PLAN_NOT_FOUND, "Plan: " + params[:id].to_s) unless subscription_plan
      subscription_plan.update_recurly_plan(params[:charge])
    end
  end
end
