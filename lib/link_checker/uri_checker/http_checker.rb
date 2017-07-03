module LinkChecker::UriChecker
  class HttpChecker < Checker
    def call
      if uri.host.nil?
        return add_error(
          summary: :invalid_url,
          message: :is_not_valid_link,
        )
      end

      check_redirects
      check_credentials_in_uri
      check_top_level_domain

      check_request
      return report if report.has_errors?

      check_meta_mature_rating
      return report if report.has_errors?

      check_google_safebrowsing

      report
    end

  private

    attr_reader :response

    INVALID_TOP_LEVEL_DOMAINS = %w(xxx adult dating porn sex sexy singles).freeze
    REDIRECT_STATUS_CODES = [301, 302, 303, 307, 308].freeze
    REDIRECT_LIMIT = 8
    REDIRECT_WARNING = 2
    RESPONSE_TIME_LIMIT = 15
    RESPONSE_TIME_WARNING = 2.5

    def check_redirects
      if redirect_history.length >= REDIRECT_LIMIT
        add_error(
          summary: :broken_redirect,
          message: :redirects_too_many_times,
          priority: -REDIRECT_LIMIT, # push it above problems of other redirects
          suggested_fix: :contact_site_administrator,
        )
      end

      if redirect_history.include?(uri)
        add_error(
          summary: :broken_redirect,
          message: :page_has_redirect_loop,
          priority: -REDIRECT_LIMIT, # push it above problems of other redirects
          suggested_fix: :contact_site_administrator,
        )
      end

      if redirect_history.length == REDIRECT_WARNING
        add_warning(
          summary: :bad_redirect,
          message: :redirects_too_many_times_slowly,
          priority: 3,
          suggested_fix: :link_directly_to,
          text_args: { uri: uri },
        )
      end
    end

    def check_credentials_in_uri
      if uri.user.present? || uri.password.present?
        add_warning(
          priority: 2,
          message: :link_contains_login_credentials,
          summary: :login_details_in_url,
          suggested_fix: :link_to_alternative_resource,
        )
      end
    end

    def check_top_level_domain
      tld = uri.host.split(".").last
      if INVALID_TOP_LEVEL_DOMAINS.include?(tld)
        add_warning(
          priority: 1,
          message: :website_for_adults,
          summary: :suspicious_destination,
        )
      end
    end

    def check_request
      start_time = Time.now
      @response = make_request(:get)
      end_time = Time.now
      response_time = end_time - start_time

      if response_time > RESPONSE_TIME_WARNING
        add_warning(
          priority: 4,
          message: :page_is_slow,
          summary: :slow_page,
          suggested_fix: :contact_site_administrator,
        )
      end

      return response if report.has_errors?

      if response.status == 404 || response.status == 410
        add_error(
          message: :page_was_not_found,
          summary: :page_not_found,
          suggested_fix: :find_content_now,
        )
      elsif response.status == 401 || response.status == 403
        add_error(
          summary: :page_requires_login,
          message: :login_required_to_view,
        )
      elsif response.status >= 400 && response.status < 500
        add_error(
          message: :this_page_is_unavailable,
          summary: :page_unavailable,
          suggested_fix: :contact_site_administrator,
          text_args: { status: response.status },
        )
      elsif response.status >= 500 && response.status < 600
        add_error(
          message: :page_is_responding_with_error,
          summary: :page_unavailable,
          suggested_fix: :contact_site_administrator,
          text_args: { status: response.status },
        )
      else
        unless response.status == 200 || REDIRECT_STATUS_CODES.include?(response.status)
          add_warning(
            message: :page_responding_unusually,
            summary: :page_unavailable,
            suggested_fix: :contact_site_administrator,
            text_args: { status: response.status },
          )
        end
      end

      response
    end

    def check_meta_mature_rating
      return unless response && response.headers["Content-Type"] == "text/html"

      page = Nokogiri::HTML(response.body)
      rating = page.css("meta[name=rating]").first&.attr("value")
      if %w(restricted mature).include?(rating)
        add_warning(
          priority: 2,
          message: :page_has_a_rating,
          summary: :suspicious_content,
          text_args: { rating: rating },
        )
      end
    end

    def check_google_safebrowsing
      api_key = Rails.application.secrets.google_api_key
      return unless api_key

      response = Faraday.post do |req|
        req.url "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=#{api_key}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          client: {
            clientId: "gds-link-checker", clientVersion: "0.1.0"
          },
          threatInfo: {
            threatTypes: %w(THREAT_TYPE_UNSPECIFIED MALWARE SOCIAL_ENGINEERING UNWANTED_SOFTWARE POTENTIALLY_HARMFUL_APPLICATION),
            platformTypes: %w(ANY_PLATFORM),
            threatEntryTypes: %w(URL),
            threatEntries: [{ url: uri.to_s }]
          }
        }.to_json
      end

      if response.status == 200
        data = JSON.parse(response.body)
        if data.include?("matches") && data["matches"]
          add_warning(
            priority: 1,
            summary: :suspicious_content,
            message: :page_contains_a_threat,
          )
        end
      else
        Airbrake.notify(
          "Unable to talk to Google Safebrowsing API!",
          status: response.status,
          body: response.body,
          headers: response.headers,
        )
      end
    end

    def make_request(method)
      begin
        response = run_connection_request(method)

        if REDIRECT_STATUS_CODES.include?(response.status) && response.headers.include?("location") && !report.has_errors?
          target_uri = uri + response.headers["location"]
          subreport = ValidUriChecker
            .new(target_uri.to_s, redirect_history: redirect_history + [uri])
            .call
          report.merge(subreport, with_priority: 1)
        end

        response
      rescue Faraday::ConnectionFailed
        add_error(
          summary: :website_unavailable,
          message: :website_host_offline,
          suggested_fix: :determine_if_temporary,
        )
        nil
      rescue Faraday::TimeoutError
        add_error(
          summary: :website_unavailable,
          message: :page_is_not_responding,
          suggested_fix: :determine_if_temporary,
        )
        nil
      rescue Faraday::SSLError
        add_error(
          summary: :security_error,
          message: :page_has_security_problem,
          suggested_fix: :determine_if_temporary,
        )
        nil
      rescue Faraday::Error => e
        add_error(
          summary: :page_unavailable,
          message: :page_failing_to_load,
          suggested_fix: :determine_if_temporary,
        )
        nil
      end
    end

    def run_connection_request(method)
      connection.run_request(method, uri, nil, nil) do |request|
        request.options[:timeout] = RESPONSE_TIME_LIMIT
        request.options[:open_timeout] = RESPONSE_TIME_LIMIT
      end
    end

    def connection
      @connection ||= Faraday.new(headers: { accept_encoding: "none" }) do |faraday|
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
