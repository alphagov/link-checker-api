module LinkMonitor
  class UpsertResourceMonitor
    def initialize(links:, app:, reference:)
      @links = links
      @app = app
      @reference = reference
    end

    def call
      monitor = ResourceMonitor.find_or_create_by(app: app, reference: reference)

      manage_links(monitor) if monitor.valid?

      monitor
    end

  private

    attr_reader :links, :app, :reference

    def create_links(monitor)
      links.each do |link|
        monitored_link = Link.find_or_create_by(uri: link)
        monitor.monitor_links.find_or_create_by(link: monitored_link)
      end
    end

    def manage_links(monitor)
      remove_old_monitor_links(monitor)
      create_links(monitor)
    end

    def old_monitor_links(monitor)
      monitor.monitor_links.includes(:link).reject { |monitor_link| links.include?(monitor_link.link.uri) }
    end

    def remove_old_monitor_links(monitor)
      old_monitor_links(monitor).map(&:delete)
    end
  end
end
