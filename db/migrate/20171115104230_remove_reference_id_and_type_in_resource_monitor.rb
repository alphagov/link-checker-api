class RemoveReferenceIdAndTypeInResourceMonitor < ActiveRecord::Migration[5.0]
  def change
    remove_column :resource_monitors, :resource_type, :string
    remove_column :resource_monitors, :resource_id, :integer, index: true
  end
end
