class CreateJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :jobs do |t|
      t.datetime :completed_at

      t.timestamps
    end
  end
end
