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

    def add_error(priority: 0, summary:, message:, suggested_fix: "", text_args: {})
      add_problem(:error, priority, summary, message, suggested_fix, text_args)
    end

    def add_warning(priority: 0, summary:, message:, suggested_fix: "", text_args: {})
      add_problem(:warning, priority, summary, message, suggested_fix, text_args)
    end

  private

    attr_reader :redirect_history

    def add_problem(type, priority, summary, message, suggested_fix, text_args)
      report.add_problem(
        Problem.new(
          type, priority,
          find_locale_string(summary, text_args),
          find_locale_string(message, text_args),
          find_locale_string(suggested_fix, text_args),
        )
      )
    end

    def find_locale_string(symbol, args)
      return "" if symbol.empty?

      symbols = [
        :"#{symbol}.#{from_redirect? ? 'redirect' : 'singular'}",
        symbol,
      ]

      string = symbols
        .map { |symbol| I18n.t(symbol, args.merge(default: nil)) }
        .compact
        .first

      raise "Invalid locale symbol." if string.nil?

      string
    end
  end
end
