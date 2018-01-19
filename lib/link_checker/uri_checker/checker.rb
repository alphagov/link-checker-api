module LinkChecker::UriChecker
  class Checker
    attr_reader :uri, :report

    def initialize(uri, redirect_history: [], http_client: nil)
      @uri = uri
      @redirect_history = redirect_history
      @report = Report.new
      @http_client = http_client
    end

    def from_redirect?
      redirect_history.any?
    end

    def add_problem(problem)
      @report.add_problem(problem)
    end

    def http_client
      @http_client ||= Faraday.new(headers: { accept_encoding: "none" }) do |faraday|
        faraday.use :cookie_jar
        faraday.adapter Faraday.default_adapter
      end
    end

  private

    attr_reader :redirect_history
  end
end
