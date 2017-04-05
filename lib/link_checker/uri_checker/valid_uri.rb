module LinkChecker::UriChecker
  class ValidUri
    HTTP_URI_SCHEMES = %w(http https)
    FILE_URI_SCHEMES = %w(file)

    attr_reader :report, :options

    def initialize(options = {})
      @report = Report.new
      @options = options
    end

    def call(uri)
      parsed_uri = URI.parse(uri)

      if parsed_uri.scheme.nil?
        report.add_warning(:no_scheme, "No scheme given.")
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, options).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, options).call)
      else
        report.add_warning(:unsupported_scheme, "Unsupported scheme.")
      end

      report
    rescue URI::InvalidURIError
      report.add_error(:uri_invalid, "Invalid URI")
      report
    end
  end
end
