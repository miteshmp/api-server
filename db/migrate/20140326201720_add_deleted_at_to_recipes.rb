class AddDeletedAtToRecipes < ActiveRecord::Migration
  def change
    add_column :recipes, :deleted_at, :timestamp
  end
end
