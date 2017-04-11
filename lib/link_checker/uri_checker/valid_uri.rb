module LinkChecker::UriChecker
  class ValidUri
    HTTP_URI_SCHEMES = %w(http https).freeze
    FILE_URI_SCHEMES = %w(file).freeze

    attr_reader :report, :options

    def initialize(options = {})
      @report = Report.new
      @options = options
    end

    def call(uri)
      parsed_uri = URI.parse(uri)

      if parsed_uri.scheme.nil?
        report.add_error(:no_scheme, "No scheme given", "Try something like http:// or https://.")
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, options).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, options).call)
      else
        report.add_warning(:unsupported_scheme, "Unsupported scheme", "Try something like http:// or https://.")
      end

      report
    rescue URI::InvalidURIError
      report.add_error(:uri_invalid, "Invalid URI", "Cannot understand the URI format.")
      report
    end
  end
end
