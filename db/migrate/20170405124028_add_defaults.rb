class AddDefaults < ActiveRecord::Migration[5.0]
  def up
    change_column :checks, :link_errors, :json, default: {}, null: false
    change_column :checks, :link_warnings, :json, default: {}, null: false

    change_column :links, :uri, :string, null: false
  end

  def down
    change_column :checks, :link_errors, :json
    change_column :checks, :link_warnings, :json

    change_column :links, :uri, :string
  end
end
