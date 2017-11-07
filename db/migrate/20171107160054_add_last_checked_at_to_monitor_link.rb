class AddLastCheckedAtToMonitorLink < ActiveRecord::Migration[5.0]
  def change
    add_column :monitor_links, :last_checked_at, :datetime, default: nil
  end
end
