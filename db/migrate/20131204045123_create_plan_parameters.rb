class CreatePlanParameters < ActiveRecord::Migration
  def change
    create_table :plan_parameters do |t|
      t.string :parameter
      t.text :value

      t.references :subscription_plan

      t.timestamps
    end
  end
end
