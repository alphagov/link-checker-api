class AddResourceTypeAndResourceIdToResourceMonitor < ActiveRecord::Migration[5.0]
  def change
    add_column :resource_monitors, :resource_type, :string
    add_column :resource_monitors, :resource_id, :integer, index: true
  end
end
