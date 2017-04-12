class AddWebhookSecretTokenToBatches < ActiveRecord::Migration[5.0]
  def change
    add_column :batches, :webhook_secret_token, :string
  end
end
