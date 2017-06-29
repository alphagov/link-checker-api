module LinkChecker::UriChecker
  class ValidUriChecker < Checker
    def call
      if parsed_uri.scheme.nil?
        add_error(
          summary: "Invalid URL",
          message: {
            singular: "This link is missing the scheme (http, ftp, mailto).",
            redirect: "This redirects to an invalid link.",
          }
        )
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif CONTACT_SCHEMES.include?(parsed_uri.scheme)
        add_warning(
          summary: "Contact details",
          message: {
            singular: "This links to contact details which we don't support.",
            redirect: "This redirects to contact details which we don't support.",
          },
          suggested_fix: "Check this are correct manually."
        )
      else
        add_warning(
          summary: "Unusual URL",
          message: {
            singular: "This links to something which we don't support.",
            redirect: "This redirects to something which we don't support.",
          },
          suggested_fix: "Check this are correct manually."
        )
      end
    rescue URI::InvalidURIError
      add_error(
        summary: "Invalid URL",
        message: {
          singular: "This is not a valid link.",
          redirect: "This redirects to an invalid link.",
        }
      )
    end

  private

    HTTP_URI_SCHEMES = %w(http https).freeze
    FILE_URI_SCHEMES = %w(file).freeze
    CONTACT_SCHEMES = %w(mailto tel).freeze

    def parsed_uri
      @parsed_uri ||= URI.parse(uri)
    end
  end
end
