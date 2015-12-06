class AddUniqueIndexToPlanParameters < ActiveRecord::Migration
  def change
  	add_index :plan_parameters, [:subscription_plan_id, :parameter],:unique => true
  end
end
