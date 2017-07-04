class AddProblemSummaryAndSuggestedFixToChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :checks, :problem_summary, :string
    add_column :checks, :suggested_fix, :string
  end
end
