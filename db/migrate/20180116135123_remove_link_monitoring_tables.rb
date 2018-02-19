class RemoveLinkMonitoringTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :link_histories
    drop_table :monitor_links
    drop_table :resource_monitors
  end
end
