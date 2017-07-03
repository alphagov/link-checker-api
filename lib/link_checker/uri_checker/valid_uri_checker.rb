module LinkChecker::UriChecker
  class ValidUriChecker < Checker
    def call
      if parsed_uri.scheme.nil?
        add_error(
          summary: I18n.t(:invalid_url),
          message: {
            singular: I18n.t("link_missing_scheme.singular"),
            redirect: I18n.t("link_missing_scheme.redirect"),
          },
          suggested_fix: I18n.t(:check_correct_manually),
        )
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif CONTACT_SCHEMES.include?(parsed_uri.scheme)
        add_warning(
          summary: I18n.t(:contact_details),
          message: {
            singular: I18n.t("links_to_contact_details.singular"),
            redirect: I18n.t("links_to_contact_details.redirect"),
          },
          suggested_fix: I18n.t(:check_correct_manually),
        )
      else
        add_warning(
          summary: I18n.t(:unusual_url),
          message: {
            singular: I18n.t("link_is_unsupported.singular"),
            redirect: I18n.t("link_is_unsupported.redirect"),
          },
          suggested_fix: I18n.t(:check_correct_manually),
        )
      end
    rescue URI::InvalidURIError
      add_error(
        summary: I18n.t(:invalid_url),
        message: {
          singular: I18n.t("not_a_valid_link.singular"),
          redirect: I18n.t("not_a_valid_link.redirect"),
        },
        suggested_fix: I18n.t(:check_correct_manually),
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
