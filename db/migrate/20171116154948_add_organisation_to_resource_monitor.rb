class AddOrganisationToResourceMonitor < ActiveRecord::Migration[5.0]
  def change
    add_column :resource_monitors, :organisation, :string, default: nil
  end
end
