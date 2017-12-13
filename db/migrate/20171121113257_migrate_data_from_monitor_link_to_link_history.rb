class MigrateDataFromMonitorLinkToLinkHistory < ActiveRecord::Migration[5.0]
  def change
    MonitorLink.find_each do |link|
      LinkHistory.create(
        link_id: link.id,
        link_errors: link.link_errors
      )
    end
  end
end