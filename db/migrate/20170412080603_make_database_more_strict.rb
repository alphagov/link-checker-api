class MakeDatabaseMoreStrict < ActiveRecord::Migration[5.0]
  def change
    change_column_null :batch_checks, :check_id, false
    change_column_null :batch_checks, :batch_id, false

    change_column_null :checks, :link_id, false
  end
end
