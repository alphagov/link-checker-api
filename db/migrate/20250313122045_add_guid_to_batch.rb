class AddGuidToBatch < ActiveRecord::Migration[8.0]
  def change
    # Enable pgcrypto extension for gen_random_uuid
    enable_extension "pgcrypto"

    # Add the new column without a default
    add_column :batches, :guid, :string, null: false

    # Tell Rails to refresh the schema for the model, since we've just updated it
    Batch.reset_column_information

    # Now we can generate a GUID for existing records
    Batch.find_each do |batch|
      batch.update_columns(guid: SecureRandom.uuid)
    end

    # Use raw SQL to set the default for the new column (pgcrypto function)
    execute "ALTER TABLE batches ALTER COLUMN guid SET DEFAULT gen_random_uuid()"

    # Add a unique index to the guid column
    add_index :batches, :guid, unique: true
  end
end
