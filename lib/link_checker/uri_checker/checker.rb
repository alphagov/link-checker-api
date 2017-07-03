module LinkChecker::UriChecker
  class Checker
    attr_reader :uri, :report

    def initialize(uri, redirect_history: [])
      @uri = uri
      @redirect_history = redirect_history
      @report = Report.new
    end

    def from_redirect?
      redirect_history.any?
    end

    def add_problem(problem)
      @report.add_problem(problem)
    end

  private

    attr_reader :redirect_history
  end
end
