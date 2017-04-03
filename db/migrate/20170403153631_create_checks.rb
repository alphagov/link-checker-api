class CreateChecks < ActiveRecord::Migration[5.0]
  def change
    create_table :checks do |t|
      t.datetime :started_at
      t.datetime :ended_at
      t.json :warnings
      t.json :errors

      t.timestamps
    end
  end
end
