module LinkChecker::UriChecker
  class NoHost < Error
    def initialize(options = {})
      super(summary: :invalid_url, message: :is_not_valid_link, **options)
    end
  end

  class TooManyRedirects < Error
    def initialize(options = {})
      super(summary: :broken_redirect, message: :redirects_too_many_times, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class RedirectLoop < Error
    def initialize(options = {})
      super(summary: :broken_redirect, message: :page_has_redirect_loop, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class TooManyRedirectsSlowly < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :bad_redirect, message: :redirects_too_many_times_slowly, suggested_fix: :link_directly_to, **options)
    end
  end

  class CredentialsInUri < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :login_details_in_url, message: :link_contains_login_credentials, suggested_fix: :link_to_alternative_resource, **options)
    end
  end

  class SuspiciousTld < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :suspicious_destination, message: :website_for_adults, **options)
    end
  end

  class SlowResponse < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :slow_page, message: :page_is_slow, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class PageNotFound < Error
    def initialize(options = {})
      super(summary: :page_not_found, message: :page_was_not_found, suggested_fix: :find_content_now, **options)
    end
  end

  class PageRequiresLogin < Error
    def initialize(options = {})
      super(summary: :page_requires_login, message: :login_required_to_view, **options)
    end
  end

  class PageIsUnavailable < Error
    def initialize(options = {})
      super(summary: :page_unavailable, message: :this_page_is_unavailable, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class PageRespondsWithError < Error
    def initialize(options = {})
      super(summary: :page_unavailable, message: :page_is_responding_with_error, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class PageRespondsUnusually < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :page_unavailable, message: :page_responding_unusually, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class PageWithRating < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :suspicious_content, message: :page_has_a_rating, **options)
    end
  end

  class PageContainsThreat < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :suspicious_content, message: :page_contains_a_threat, **options)
    end
  end

  class SecurityProblem < LinkChecker::UriChecker::Warning
    def initialize(options = {})
      super(summary: :security_problem, message: :page_has_security_problem, suggested_fix: :contact_site_administrator, **options)
    end
  end

  class HttpCommunicationError < Error
    def initialize(options = {})
      super(suggested_fix: :determine_if_temporary, **options)
    end
  end

  class HttpChecker < Checker
    def call
      if uri.host.blank?
        return add_problem(NoHost.new(from_redirect: from_redirect?))
      end

      check_redirects
      check_credentials_in_uri
      check_top_level_domain

      check_request
      return report if report.has_errors?

      check_meta_mature_rating
      return report if report.has_errors?

      report
    end

  private

    attr_reader :response

    INVALID_TOP_LEVEL_DOMAINS = %w[xxx adult dating porn sex sexy singles].freeze
    REDIRECT_STATUS_CODES = [301, 302, 303, 307, 308].freeze
    REDIRECT_LIMIT = 8
    REDIRECT_LOOP_LIMIT = 5
    REDIRECT_WARNING = 2
    RESPONSE_TIME_LIMIT = 15
    RESPONSE_TIME_WARNING = 5

    def check_redirects
      add_problem(TooManyRedirects.new(from_redirect: from_redirect?)) if redirect_history.length >= REDIRECT_LIMIT
      add_problem(RedirectLoop.new(from_redirect: from_redirect?)) if redirect_history.count(uri) >= REDIRECT_LOOP_LIMIT
      add_problem(TooManyRedirectsSlowly.new(from_redirect: :from_redirect?, uri:)) if redirect_history.length == REDIRECT_WARNING
    end

    def check_credentials_in_uri
      if uri.user.present? || uri.password.present?
        add_problem(CredentialsInUri.new(from_redirect: from_redirect?))
      end
    end

    def check_top_level_domain
      tld = uri.host.split(".").last
      if INVALID_TOP_LEVEL_DOMAINS.include?(tld)
        add_problem(SuspiciousTld.new(from_redirect: from_redirect?))
      end
    end

    def check_request
      start_time = Time.zone.now
      @response = make_request(:get)
      end_time = Time.zone.now
      response_time = end_time - start_time

      return response if report.has_errors? || response.nil?

      add_problem(SlowResponse.new(from_redirect: from_redirect?)) if response_time > RESPONSE_TIME_WARNING

      if response.status == 404 || response.status == 410
        add_problem(PageNotFound.new(from_redirect: from_redirect?))
      elsif response.status == 401 || response.status == 403
        add_problem(PageRequiresLogin.new(from_redirect: from_redirect?))
      elsif response.status >= 400 && response.status < 500
        add_problem(PageIsUnavailable.new(from_redirect: from_redirect?, status: response.status))
      elsif response.status >= 500 && response.status < 600
        add_problem(PageRespondsWithError.new(from_redirect: from_redirect?, status: response.status))
      elsif !(response.status == 200 || REDIRECT_STATUS_CODES.include?(response.status))
        add_problem(PageRespondsUnusually.new(from_redirect: from_redirect?, status: response.status))
      end

      response
    end

    def check_meta_mature_rating
      return unless response && response.headers["Content-Type"] == "text/html"

      page = Nokogiri::HTML(response.body)
      rating = page.css("meta[name=rating]").first&.attr("value")
      if %w[restricted mature].include?(rating)
        add_problem(PageWithRating.new(from_redirect: from_redirect?, rating:))
      end
    end

    def make_request(method, check_ssl: true)
      response = run_connection_request(method, check_ssl:)

      if REDIRECT_STATUS_CODES.include?(response.status) && response.headers.include?("location") && !report.has_errors?
        target_uri = uri + response.headers["location"]
        subreport = ValidUriChecker
          .new(target_uri.to_s, redirect_history: redirect_history + [uri], http_client:)
          .call
        report.merge(subreport)
      end

      response
    rescue Faraday::ConnectionFailed
      add_problem(
        HttpCommunicationError.new(
          summary: :website_unavailable,
          message: :website_host_offline,
          from_redirect: from_redirect?,
        ),
      )
      nil
    rescue Faraday::TimeoutError
      add_problem(
        HttpCommunicationError.new(
          summary: :website_unavailable,
          message: :page_is_not_responding,
          from_redirect: from_redirect?,
        ),
      )
      nil
    rescue Faraday::SSLError
      # if we've ended up here again, just abort
      return nil unless check_ssl

      add_problem(
        SecurityProblem.new(
          from_redirect: from_redirect?,
        ),
      )

      # retry the request with lenient handling of SSL errors, as
      # the page might have other problems.
      make_request(method, check_ssl: false)
    rescue Faraday::Error
      add_problem(
        HttpCommunicationError.new(
          summary: :page_unavailable,
          message: :technical_error_on_page,
          from_redirect: from_redirect?,
        ),
      )
      nil
    # Ruby net-http cannot handle responses with headers with CR/LF characters in, and such responses raise
    # an argument error. We want to catch these and add to the report for now, rather than continuing to raise these
    # as errors, which can trigger alerting. We are planning on raising this to be fixed at the net-http level which may
    # mean we do not have to handle these here.
    # Doing some fuzzy matching on the error message to try and ensure a bit of resilience, allowing for changes to the
    # exact error message in the exception.
    rescue ArgumentError => e
      raise e unless e.message =~ /(.*)header(.*) CR\/LF/

      add_problem(
        HttpCommunicationError.new(
          summary: :page_unavailable,
          message: :technical_error_on_page,
          from_redirect: from_redirect?,
        ),
      )
      nil
    end

    def run_connection_request(method, check_ssl: true)
      client = check_ssl ? http_client : insecure_http_client
      client.run_request(method, uri.normalize, nil, additional_connection_headers) do |request|
        request.options[:timeout] = RESPONSE_TIME_LIMIT
        request.options[:open_timeout] = RESPONSE_TIME_LIMIT
      end
    end

    def gov_uk_uri?
      @gov_uk_uri ||= Plek.new.website_root.include?(uri.host)
    end

    def gov_uk_upload_uri?
      uri.path.starts_with? "/government/uploads"
    end

    def rate_limit_header
      return {} unless gov_uk_uri?

      { "Rate-Limit-Token": Rails.application.secrets.govuk_rate_limit_token }
    end

    def basic_authorization_header
      return {} unless LinkCheckerApi.hosts_with_basic_authorization.include?(uri.host)

      { "Authorization": "Basic #{base64_encode_authorization(uri.host)}" }
    end

    def additional_connection_headers
      {}
        .merge(rate_limit_header)
        .merge(basic_authorization_header)
    end

    def base64_encode_authorization(host)
      Base64.encode64(LinkCheckerApi.hosts_with_basic_authorization[host])
    end
  end
end
