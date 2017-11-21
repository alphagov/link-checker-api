module LinkMonitor
  class CheckMonitoredLinks
    def initialize(resource_monitor:)
      @resource_monitor = resource_monitor
    end

    def call
      resource_monitor.links.includes(:checks, :link_history).each { |link| check_link(link) }
    end

  private

    attr_reader :resource_monitor

    def check_link(link)
      if requires_check?(link)
        create_check(link)
      end

      update_link_history(link)
    end

    def update_link_history(link)
      link_history = link.link_history ||= link.create_link_history
      check = link.checks.order(completed_at: :desc).first

      if check.link_errors.any?
        link_history.add_errors(check.link_errors)
      else
        link_history.clear_errors
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
