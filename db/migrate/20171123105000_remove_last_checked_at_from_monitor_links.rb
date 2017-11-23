class RemoveLastCheckedAtFromMonitorLinks < ActiveRecord::Migration[5.0]
  def change
    remove_column :monitor_links, :last_checked_at, :datetime
  end
end
