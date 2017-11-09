class AddLinkErrorsToMonitorLink < ActiveRecord::Migration[5.0]
  def change
    add_column :monitor_links, :link_errors, :json, default: []
  end
end
