class RenameCheckWarningsAndErrors < ActiveRecord::Migration[5.0]
  def change
    rename_column :checks, :errors, :link_errors
    rename_column :checks, :warnings, :link_warnings
  end
end
