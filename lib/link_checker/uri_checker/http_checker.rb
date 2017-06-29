module LinkChecker::UriChecker
  class HttpChecker < Checker
    def call
      if uri.host.nil?
        return add_error(
          summary: "Invalid URL",
          message: {
            singular: "This is not a valid link.",
            redirect: "This redirects to an invalid link.",
          }
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
          summary: "Broken Redirect",
          message: "This redirects too many times and browsers may not open it.",
          priority: -REDIRECT_LIMIT, # push it above problems of other redirects
          suggested_fix: "Contact the site administrator to see if they have an issue that can be fixed.",
        )
      end

      if redirect_history.include?(uri)
        add_error(
          summary: "Broken Redirect",
          message: "This page has a redirect loop and won't open.",
          priority: -REDIRECT_LIMIT, # push it above problems of other redirects
          suggested_fix: "Contact the site administrator to see if they have an issue that can be fixed.",
        )
      end

      if redirect_history.length == REDIRECT_WARNING
        add_warning(
          summary: "Bad Redirect",
          message: "This redirects too many times and will open slowly",
          priority: 3,
          suggested_fix: "Link directly to: #{uri}"
        )
      end
    end

    def check_credentials_in_uri
      if uri.user.present? || uri.password.present?
        add_warning(
          priority: 2,
          message: "This link contains login credentials which you may not want to share publicly.",
          summary: "Login details in URL",
          suggested_fix: "Link to an alternative location of this resource, which doesn't require credentials.",
        )
      end
    end

    def check_top_level_domain
      tld = uri.host.split(".").last
      if INVALID_TOP_LEVEL_DOMAINS.include?(tld)
        add_warning(
          priority: 1,
          message: {
            singular: "This link is hosted on a website meant for adult content.",
            redirect: "This redirects to websites meant for adult content.",
          },
          summary: "Suspicious destination"
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
          message: {
            singular: "This page is slow loading and may frustrate users.",
            redirect: "This redirects to a slow loading page.",
          },
          summary: "Slow page",
          suggested_fix: "Contact the site administrator to see if they have an issue that can be fixed",
        )
      end

      return response if report.has_errors?

      if response.status == 404 || response.status == 410
        add_error(
          message: {
            singular: "This page was not found (404).",
            redirect: "This redirects to a page not found (404).",
          },
          summary: "Page not found",
          suggested_fix: "Find where the content is now hosted and link to that instead.",
        )
      elsif response.status == 401 || response.status == 403
        add_error(
          summary: "Page requires login",
          message: {
            singular: "A login is required to view this page.",
            redirect: "This redirects to a page that requires a login.",
          },
        )
      elsif response.status >= 400 && response.status < 500
        add_error(
          message: {
            singular: "This page is unavailable (#{response.status}).",
            redirect: "This redirects to a page that is unavailable (#{response.status}).",
          },
          summary: "Page unavailable",
          suggested_fix: "Contact the site administrator to see if they have an issue that can be fixed.",
        )
      elsif response.status >= 500 && response.status < 600
        add_error(
          message: {
            singular: "This page is responding with an error (#{response.status}) and won't work for users.",
            redirect: "This redirects to a page with an error.",
          },
          summary: "Page unavailable",
          suggested_fix: "Contact the site administrator to see if they have an issue that can be fixed.",
        )
      else
        unless response.status == 200 || REDIRECT_STATUS_CODES.include?(response.status)
          add_warning(
            message: {
              singular: "This page is responding unusually (#{response.status}) and likely won't work for users.",
              redirect: "This redirects to a page responding unusally (#{response.status}).",
            },
            summary: "Page unavailable",
            suggested_fix: "Contact the site administrator to see if they have an issue that can be fixed.",
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
          message: {
            singular: "This page describes itself as '#{rating}' and may not be suitable to link to.",
            redirect: "This redirects to a page that describes it's content as '#{rating}'.",
          },
          summary: "Suspicious content",
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
            summary: "Suspicious content",
            message: {
              singular: "This page contains a threat and should not be linked to.",
              redirect: "This redirects to a page with a threat",
            },
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
          summary: "Website unavailable",
          message: {
            singular: "The website hosting this link is offline.",
            redirect: "This redirects to a website that is offline.",
          },
          suggested_fix: "Determine if this is a temporary issue or the website is no longer available.",
        )
        nil
      rescue Faraday::TimeoutError
        add_error(
          summary: "Website unavailable",
          message: {
            singular: "This page is not responding.",
            redirect: "This redirects to a page that is not responding."
          },
          suggested_fix: "Determine if this is a temporary issue or the resource is no longer available",
        )
        nil
      rescue Faraday::SSLError
        add_error(
          summary: "Security Error",
          message: {
            singular: "This page has a security problem that users will be alerted to.",
            redirect: "This redirects to a page with a security problem."
          },
        )
        nil
      rescue Faraday::Error => e
        add_error(
          summary: "Page unavailable",
          message: {
            singular: "This page is failing to load.",
            redirect: "This redirects to a page that isn't loading.",
          },
          suggested_fix: "Determine if this is a temporary issue or the website is no longer available",
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
