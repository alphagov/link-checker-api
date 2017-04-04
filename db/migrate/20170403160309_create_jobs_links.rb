class CreateJobsLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :jobs_links do |t|
      t.belongs_to :job, index: true
      t.belongs_to :link, index: true
    end
  end
end
