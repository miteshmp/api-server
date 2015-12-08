class CreateApiCallIssues < ActiveRecord::Migration
  def change
    create_table :api_call_issues do |t|
      t.string :api_type
      t.string :error_reason
      t.string :error_data
      t.integer :count,:default => 0

      t.timestamps
    end
    add_index :api_call_issues, [:api_type, :error_reason, :error_data], :unique => true, :name => 'issue_index'
  end
end
