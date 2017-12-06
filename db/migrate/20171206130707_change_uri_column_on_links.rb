class ChangeUriColumnOnLinks < ActiveRecord::Migration[5.0]
  def up
    change_column :links, :uri, :text, null: false
  end

  def down
    change_column :links, :uri, :string, null: false
  end
end
