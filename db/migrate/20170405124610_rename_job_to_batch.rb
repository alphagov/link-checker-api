class RenameJobToBatch < ActiveRecord::Migration[5.0]
  def change
    rename_table :jobs, :batches
    rename_table :jobs_links, :batches_links
    rename_column :batches_links, :job_id, :batch_id
  end
end
