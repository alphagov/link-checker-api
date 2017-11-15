class AddReferenceToResourceMonitor < ActiveRecord::Migration[5.0]
  def change
    add_column :resource_monitors, :reference, :string, default: 'bar', null: false, index: true
    change_column_default :resource_monitors, :reference, nil
  end
end
