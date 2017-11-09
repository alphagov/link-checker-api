require "sidekiq-scheduler"

class ScheduleResourceMonitorWorker
  include Sidekiq::Worker

  def perform
    enabled_monitors.each do |monitor_id|
      ResourceMonitorWorker.perform_async(monitor_id)
    end
  end

private

  def enabled_monitors
    ResourceMonitor.where(enabled: true).pluck(:id)
  end
end
