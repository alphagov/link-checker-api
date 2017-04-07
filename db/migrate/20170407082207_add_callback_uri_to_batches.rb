class AddCallbackUriToBatches < ActiveRecord::Migration[5.0]
  def change
    add_column :batches, :callback_uri, :string
  end
end
