module LinkChecker::UriChecker
  class ValidUri
    HTTP_URI_SCHEMES = %w(http https).freeze
    FILE_URI_SCHEMES = %w(file).freeze
    OTHER_SCHEMES = %w(mailto tel).freeze

    attr_reader :report, :options

    def initialize(options = {})
      @report = Report.new
      @options = options
    end

    def call(uri)
      parsed_uri = URI.parse(uri)

      if parsed_uri.scheme.nil?
        report.add_error("Invalid URL", "URLs for external sites must start with 'http://' or 'https://'. If you're linking to a heading on your page, use '#'.")
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, options).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, options).call)
      elsif OTHER_SCHEMES.include?(parsed_uri.scheme)
        report.add_warning("Contact details", "Check these are correct manually.")
      else
        report.add_warning("Unusual URL", "Check this is meant to be here.")
      end

      report
    rescue URI::InvalidURIError
      report.add_error("Invalid URL", "URL may be missing a forward slash at the beginning or be placeholder text.")
      report
    end
  end
end
