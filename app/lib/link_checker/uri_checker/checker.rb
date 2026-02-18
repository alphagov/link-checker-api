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

    delegate :add_problem, to: :@report

    def http_client
      @http_client ||= client
    end

    def insecure_http_client
      @insecure_http_client ||= client(ssl: { verify: false })
    end

  private

    attr_reader :redirect_history

    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 (GOV.UK Link Checker API)".freeze

    def client(options = {})
      default_options = { headers: { accept_encoding: "none", user_agent: USER_AGENT } }
      Faraday.new(default_options.merge(options)) do |faraday|
        faraday.use :cookie_jar
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
