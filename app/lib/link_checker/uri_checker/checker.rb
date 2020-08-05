module LinkChecker::UriChecker
  class Checker
    attr_reader :uri, :report

    def initialize(uri, redirect_history: [], http_client: nil, insecure_http_client: nil)
      @uri = uri
      @redirect_history = redirect_history
      @report = Report.new
      @http_client = http_client
      @insecure_http_client = insecure_http_client
    end

    def from_redirect?
      redirect_history.any?
    end

    def add_problem(problem)
      @report.add_problem(problem)
    end

    def http_client
      @http_client ||= client
    end

    def insecure_http_client
      @insecure_http_client ||= client(ssl: { verify: false })
    end

  private

    attr_reader :redirect_history

    def client(options = {})
      default_options = { headers: { accept_encoding: "none" } }
      Faraday.new(default_options.merge(options)) do |faraday|
        faraday.use :cookie_jar
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
