class AddDeletionCascadeToBatchesAndChecks < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :batch_checks, :batches
    add_foreign_key :batch_checks, :batches, on_delete: :cascade
  end
end
