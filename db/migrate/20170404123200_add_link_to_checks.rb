class AddLinkToChecks < ActiveRecord::Migration[5.0]
  def change
    add_belongs_to(:checks, :link, index: true)
  end
end
