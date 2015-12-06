class CreateActionConfig < ActiveRecord::Migration
	def change
		create_table :action_configs do |t|
      		t.string :action_name
      		t.string :action_value
      		t.string :action_rule

      		t.timestamps
    	end
	end
end
