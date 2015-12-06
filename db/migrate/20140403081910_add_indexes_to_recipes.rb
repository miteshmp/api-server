class AddIndexesToRecipes < ActiveRecord::Migration
  def change
  	add_index :recipes, :program_code
    add_index :recipes, :name
    add_index :recipes, :device_model_id
  end
end