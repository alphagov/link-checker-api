class CreateLinkHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :link_histories do |t|
      t.json :link_errors, default: []
      t.belongs_to :link

      t.timestamps
    end
  end
end
