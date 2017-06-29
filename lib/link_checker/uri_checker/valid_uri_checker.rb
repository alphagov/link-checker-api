module LinkChecker::UriChecker
  class ValidUriChecker
    attr_reader :uri, :report

    def initialize(uri, redirect_history: [])
      @uri = uri
      @redirect_history = redirect_history
      @report = Report.new
    end

    def call
      parsed_uri = URI.parse(uri)

      if parsed_uri.scheme.nil?
        report.add_problem(NO_SCHEME_PROBLEM)
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif OTHER_SCHEMES.include?(parsed_uri.scheme)
        report.add_problem(OTHER_SCHEME_PROBLEM)
      else
        report.add_problem(UNUSUAL_URL_PROBLEM)
      end

      report
    rescue URI::InvalidURIError
      report.add_problem(INVALID_URL_PROBLEM)
      report
    end

  private

    attr_reader :redirect_history

    HTTP_URI_SCHEMES = %w(http https).freeze
    FILE_URI_SCHEMES = %w(file).freeze
    OTHER_SCHEMES = %w(mailto tel).freeze

    NO_SCHEME_PROBLEM = Problem.new(:error, 0, "Invalid URL", "URLs for external sites must start with 'http://' or 'https://'.", "Make sure to use a full URL. If you're linking to a heading on your page, use '#'.")
    INVALID_URL_PROBLEM = Problem.new(:error, 0, "Invalid URL", "URL may be missing a forward slash at the beginning or be placeholder text.", "Double check to make sure your URL is correct.")
    OTHER_SCHEME_PROBLEM = Problem.new(:warning, 0, "Contact details", "Link cannot be checked automatically.", "Check these are correct manually.")
    UNUSUAL_URL_PROBLEM = Problem.new(:warning, 0, "Unusual URL", "Link cannot be checked automatically.", "Check this is meant to be here.")
  end
end
