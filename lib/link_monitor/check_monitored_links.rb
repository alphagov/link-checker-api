module LinkMonitor
  class CheckMonitoredLinks
    def initialize(resource_monitor:)
      @resource_monitor = resource_monitor
    end

    def call
      resource_monitor.links.includes(:checks).each { |link| check_link(link) }
    end

  private

    attr_reader :resource_monitor

    def check_link(link)
      if requires_check?(link)
        create_check(link)
      end

      update_monitor_link(link)
    end

    def update_monitor_link(link)
      monitor_link = resource_monitor.monitor_links.find_by(link_id: link.id)
      check = link.checks.order(completed_at: :desc).first

      monitor_link.touch(:last_checked_at)

      if check.link_errors.any?
        monitor_link.add_errors(check.link_errors)
      else
        monitor_link.clear_errors
      end
    end

    def requires_check?(link)
      link.checks.none? { |check| check.completed_at > 8.hours.ago }
    end

    def create_check(link)
      check = Check.create(link_id: link.id)

      CheckWorker.run(check.id, synchronous: true)
    end
  end
end
