class RemoveLinkErrorsFromMonitorLinks < ActiveRecord::Migration[5.0]
  def change
    remove_column :monitor_links, :link_errors, :json
  end
end
