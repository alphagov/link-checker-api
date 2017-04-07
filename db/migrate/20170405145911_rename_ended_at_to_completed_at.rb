class RenameEndedAtToCompletedAt < ActiveRecord::Migration[5.0]
  def change
    rename_column :checks, :completed_at, :completed_at
  end
end
