class MonitorController < ApplicationController
  def create
    monitor = LinkMonitor::UpsertResourceMonitor.new(links: permitted_params[:links], service: permitted_params[:service], resource_type: permitted_params[:resource_type], resource_id: permitted_params[:resource_id]).call

    monitor.validate!

    render(json: monitor_report(monitor), status: 200)
  end

private

  def permitted_params
    params.permit(:service, :resource_type, :resource_id, links: [])
  end

  def monitor_report(monitor)
    { id: monitor.id }
  end
end
