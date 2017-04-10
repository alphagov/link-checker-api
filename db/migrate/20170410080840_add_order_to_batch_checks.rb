class AddOrderToBatchChecks < ActiveRecord::Migration[5.0]
  def change
    add_column :batch_checks, :order, :integer, null: false, default: 0
  end
end
