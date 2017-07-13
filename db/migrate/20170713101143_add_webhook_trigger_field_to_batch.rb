class AddWebhookTriggerFieldToBatch < ActiveRecord::Migration[5.0]
  def change
    add_column :batches, :webhook_triggered, :boolean, null: false, default: false
  end
end
