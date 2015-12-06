class AddPlanChangedAtToDevice < ActiveRecord::Migration
  def change
    add_column :devices, :plan_changed_at, :datetime, :after => :plan_id
  end
end
