class MonitorController < ApplicationController
  def create
    monitor = LinkMonitor::UpsertResourceMonitor.new(
      links: permitted_params[:links],
      app: permitted_params[:app], reference: permitted_params[:reference],
      organisation: permitted_params[:organisation]
    ).call

    monitor.validate!

    render(json: monitor_report(monitor), status: 200)
  end

private

  def permitted_params
    params.permit(:organisation, :app, :reference, links: [])
  end

  def monitor_report(monitor)
    { id: monitor.id }
  end
end
