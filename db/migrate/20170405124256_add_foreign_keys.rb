class AddForeignKeys < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :checks, :links
    add_foreign_key :jobs_links, :jobs
    add_foreign_key :jobs_links, :links
  end
end
