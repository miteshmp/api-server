class FixModelCode < ActiveRecord::Migration
 def change
    rename_column :device_models, :code, :model_no
  end
end
