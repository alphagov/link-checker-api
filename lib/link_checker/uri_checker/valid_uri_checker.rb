module LinkChecker::UriChecker
  class MissingUriScheme < Error
    def initialize(options = {})
      super(summary: :invalid_url, message: :link_missing_scheme, suggested_fix: :check_correct_manually, **options)
    end
  end

  class InvalidUri < Error
    def initialize(options = {})
      super(summary: :invalid_url, message: :not_a_valid_link, suggested_fix: :check_correct_manually, **options)
    end
  end

  class ContactDetails < Warning
    def initialize(options = {})
      super(summary: :contact_details, message: :links_to_contact_details, suggested_fix: :check_correct_manually, **options)
    end
  end

  class UnusualUrl < Warning
    def initialize(options = {})
      super(summary: :unusual_url, message: :link_is_unsupported, suggested_fix: :check_correct_manually, **options)
    end
  end

  class ValidUriChecker < Checker
    def call
      if parsed_uri.scheme.nil?
        add_problem(MissingUriScheme.new(from_redirect: from_redirect?))
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(HttpChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge(FileChecker.new(parsed_uri, redirect_history: redirect_history).call)
      elsif CONTACT_SCHEMES.include?(parsed_uri.scheme)
        add_problem(ContactDetails.new(from_redirect: from_redirect?))
      else
        add_problem(UnusualUrl.new(from_redirect: from_redirect?))
      end
    rescue URI::InvalidURIError
      add_problem(InvalidUri.new(from_redirect: from_redirect?))
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
