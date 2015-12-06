class DropPlans < ActiveRecord::Migration
  def up
  	drop_table :plans
  end

  def down
  end
end
