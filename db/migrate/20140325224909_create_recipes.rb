class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :name
      t.integer :program_code
      t.string :default_duration
      t.string :min_duration
      t.string :max_duration
      t.integer :device_model_id

      t.timestamps
    end
  end
end
