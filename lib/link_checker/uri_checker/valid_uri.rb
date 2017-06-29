module LinkChecker::UriChecker
  class ValidUri
    attr_reader :report, :options

    def initialize(options = {})
      @report = Report.new
      @options = options
    end

    def call(uri)
      parsed_uri = URI.parse(uri)

      if parsed_uri.scheme.nil?
        report.add_problem(NO_SCHEME_PROBLEM)
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, options).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, options).call)
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

    HTTP_URI_SCHEMES = %w(http https).freeze
    FILE_URI_SCHEMES = %w(file).freeze
    OTHER_SCHEMES = %w(mailto tel).freeze

    NO_SCHEME_PROBLEM = Problem.new(:error, 0, "Invalid URL", "URLs for external sites must start with 'http://' or 'https://'.", "Make sure to use a full URL. If you're linking to a heading on your page, use '#'.")
    INVALID_URL_PROBLEM = Problem.new(:error, 0, "Invalid URL", "URL may be missing a forward slash at the beginning or be placeholder text.", "Double check to make sure your URL is correct.")
    OTHER_SCHEME_PROBLEM = Problem.new(:warning, 0, "Contact details", "Link cannot be checked automatically.", "Check these are correct manually.")
    UNUSUAL_URL_PROBLEM = Problem.new(:warning, 0, "Unusual URL", "Link cannot be checked automatically.", "Check this is meant to be here.")
  end
end
