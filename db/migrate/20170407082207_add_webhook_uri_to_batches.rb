class AddWebhookUriToBatches < ActiveRecord::Migration[5.0]
  def change
    add_column :batches, :webhook_uri, :string
  end
end
