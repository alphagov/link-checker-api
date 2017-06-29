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

    def add_error(priority: 0, summary:, message:, suggested_fix: "")
      add_problem(:error, priority, summary, message, suggested_fix)
    end

    def add_warning(priority: 0, summary:, message:, suggested_fix: "")
      add_problem(:warning, priority, summary, message, suggested_fix)
    end

  private

    attr_reader :redirect_history

    def add_problem(type, priority, summary, message, suggested_fix)
      report.add_problem(
        Problem.new(
          pick_singular_or_redirect(type),
          pick_singular_or_redirect(priority),
          pick_singular_or_redirect(summary),
          pick_singular_or_redirect(message),
          pick_singular_or_redirect(suggested_fix)
        )
      )
    end

    def pick_singular_or_redirect(thing)
      if thing.is_a?(Hash)
        thing[from_redirect? ? :redirect : :singular]
      else
        thing
      end
    end
  end
end
