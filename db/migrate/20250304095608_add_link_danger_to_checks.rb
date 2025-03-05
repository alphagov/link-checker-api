class AddLinkDangerToChecks < ActiveRecord::Migration[8.0]
  def change
    add_column :checks, :link_danger, :string, array: true, default: [], null: false
  end
end
