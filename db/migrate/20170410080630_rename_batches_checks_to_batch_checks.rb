class RenameBatchesChecksToBatchChecks < ActiveRecord::Migration[5.0]
  def change
    rename_table :batches_checks, :batch_checks
  end
end
