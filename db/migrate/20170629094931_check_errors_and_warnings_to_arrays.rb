class CheckErrorsAndWarningsToArrays < ActiveRecord::Migration[5.0]
  def change
    change_column_default :checks, :link_warnings, nil
    change_column_default :checks, :link_errors, nil

    change_column :checks, :link_warnings, "character varying[] USING array[]::character varying[]"
    change_column :checks, :link_errors, "character varying[] USING array[]::character varying[]"

    change_column_default :checks, :link_warnings, []
    change_column_default :checks, :link_errors, []
  end
end
