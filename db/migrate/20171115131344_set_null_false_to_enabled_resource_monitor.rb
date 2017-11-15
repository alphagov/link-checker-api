class SetNullFalseToEnabledResourceMonitor < ActiveRecord::Migration[5.0]
  def change
    change_column_null :resource_monitors, :enabled, false
  end
end
