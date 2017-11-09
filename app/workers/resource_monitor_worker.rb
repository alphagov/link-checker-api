class ResourceMonitorWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options retry: 3

  def perform(monitor_id)
    resource_monitor = ResourceMonitor.find(monitor_id)

    LinkMonitor::CheckMonitoredLinks.new(resource_monitor: resource_monitor).call
  end
end
