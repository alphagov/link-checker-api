class MonitorController < ApplicationController
  def create
    monitor = LinkMonitor::CreateResourceMonitor.new(links: permitted_params[:links], service: permitted_params[:service]).call

    monitor.validate!

    render(json: monitor_report(monitor), status: 200)
  end

private

  def permitted_params
    params.permit(:service, links: [])
  end

  def monitor_report(monitor)
    { id: monitor.id }
  end
end
