class CreateMonitorLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :monitor_links do |t|
      t.belongs_to :link
      t.belongs_to :resource_monitor
    end
  end
end
