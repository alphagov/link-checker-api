class AssociateBatchesWithChecks < ActiveRecord::Migration[5.0]
  def up
    remove_column :batches, :completed_at
    remove_foreign_key :batches_links, :links
    rename_column :batches_links, :link_id, :check_id
    rename_table :batches_links, :batches_checks
    add_foreign_key :batches_checks, :checks
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
