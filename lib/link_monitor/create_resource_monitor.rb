module LinkMonitor
  class CreateResourceMonitor
    def initialize(links:, service:)
      @links = links
      @service = service
    end

    def call
      monitor = ResourceMonitor.create(service: service)

      create_links(monitor) if monitor.valid?

      monitor
    end

  private

    attr_reader :links, :service

    def create_links(monitor)
      links.each do |link|
        monitored_link = Link.find_or_create_by(uri: link)
        monitor.monitor_links.find_or_create_by(link: monitored_link)
      end
    end
  end
end
