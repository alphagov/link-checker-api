class CreateLinkHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :link_histories do |t|
      t.json :link_errors, default: [], null: false
      t.references :link, index: true, foreign_key: true, null: false

      t.timestamps
    end
  end
end
