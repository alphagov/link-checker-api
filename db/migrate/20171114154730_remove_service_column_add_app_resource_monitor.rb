class RemoveServiceColumnAddAppResourceMonitor < ActiveRecord::Migration[5.0]
  def change
    remove_column :resource_monitors, :service, :string
    add_column :resource_monitors, :app, :string, default: 'foo', null: false, index: true
    change_column_default :resource_monitors, :app, nil
  end
end
