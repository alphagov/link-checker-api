module LinkChecker::UriChecker
  class ValidUriChecker < Checker
    def call
      if parsed_uri.scheme.nil?
        add_error(
          summary: :invalid_url,
          message: :link_missing_scheme,
          suggested_fix: :check_correct_manually,
        )
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif CONTACT_SCHEMES.include?(parsed_uri.scheme)
        add_warning(
          summary: :contact_details,
          message: :links_to_contact_details,
          suggested_fix: :check_correct_manually,
        )
      else
        add_warning(
          summary: :unusual_url,
          message: :link_is_unsupported,
          suggested_fix: :check_correct_manually,
        )
      end
    rescue URI::InvalidURIError
      add_error(
        summary: :invalid_url,
        message: :not_a_valid_link,
        suggested_fix: :check_correct_manually,
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
