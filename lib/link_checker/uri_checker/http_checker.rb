module LinkChecker::UriChecker
  class HttpChecker
    INVALID_TOP_LEVEL_DOMAINS = %w(xxx adult dating porn sex sexy singles).freeze
    REDIRECT_STATUS_CODES = [301, 302, 303, 307, 308].freeze
    REDIRECT_LIMIT = 8
    REDIRECT_WARNING = 2
    RESPONSE_TIME_LIMIT = 15
    RESPONSE_TIME_WARNING = 2.5

    attr_reader :uri, :redirect_history, :report

    def initialize(uri, redirect_history: [])
      @uri = uri
      @redirect_history = redirect_history
      @report = Report.new
    end

    def call
      if uri.host.nil?
        report.add_error("Invalid URL", "No host is given in the URL.")
        return report
      end

      check_redirects
      check_top_level_domain
      check_credentials

      head_response = check_head_request
      return report if report.has_errors?

      check_get_request if head_response && head_response.headers["Content-Type"] == "text/html"
      return report if report.has_errors?

      check_google_safebrowsing

      report
    end

  private

    def check_redirects
      report.add_error("Too many redirects", "There are too many redirects set up on this url - it won't work. Find where the content is now hosted and link there instead.") if redirect_history.length >= REDIRECT_LIMIT
      report.add_error("Circular redirect", "This page automatically sends users to another page, which automatically sends them back again. Neither page will load for the user.") if redirect_history.include?(uri)
      report.add_warning("Slow page load", "Several redirects are set up on this URL - it will load slowly. Find where the content is now hosted and link to that instead.") if redirect_history.length == REDIRECT_WARNING
    end

    def check_top_level_domain
      tld = uri.host.split(".").last
      if INVALID_TOP_LEVEL_DOMAINS.include?(tld)
        report.add_warning("Suspicious URL", "This URL contains the word '#{tld}'. Check if it's appropriate to send users here.")
      end
    end

    def check_credentials
      if uri.user.present? || uri.password.present?
        report.add_warning("Login details in URL", "Check it's ok for these to be public.")
      end
    end

    def check_head_request
      start_time = Time.now
      response = make_request(:head)
      end_time = Time.now
      response_time = end_time - start_time

      report.add_warning("Slow page load", "Pages on this site take more than #{RESPONSE_TIME_WARNING} seconds to load - this may be frustrating for users.") if response_time > RESPONSE_TIME_WARNING

      return response if report.has_errors?

      if response.status == 404 || response.status == 410
        report.add_error("404 error (page not found)", "Received #{response.status} response from the server.")
      elsif response.status == 401 || response.status == 403
        report.add_error("Access denied", "You need a password to access this site. If you gave a password, it wasn't correct.")
      elsif response.status >= 400 && response.status < 500
        report.add_error("Unusual response", "Speak to your technical team. Received #{response.status} response from the server.")
      elsif response.status >= 500 && response.status < 600
        report.add_error("500 (server error)", "Received #{response.status} response from the server.")
      else
        unless response.status == 200 || REDIRECT_STATUS_CODES.include?(response.status)
          report.add_warning("Unusual response", "Speak to your technical team. Received #{response.status} response from the server.")
        end
      end

      response
    end

    def check_get_request
      response = make_request(:get)
      return unless response

      page = Nokogiri::HTML(response.body)
      rating = page.css("meta[name=rating]").first&.attr("value")
      if %w(restricted mature).include?(rating)
        report.add_warning("Possible adult content", "This site describes itself as '#{rating}'. Check if it's appropriate to send users here.")
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
          report.add_warning("Flagged as dangerous", "This site has been flagged as dangerous by Google Safebrowsing API. Don't send users to this site.")
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
          subreport = ValidUri
            .new(redirect_history: redirect_history + [uri])
            .call(target_uri.to_s)
          report.merge(subreport)
        end

        response
      rescue Faraday::ConnectionFailed
        report.add_error("Connection failed", "Connection to the server could not be established.")
      rescue Faraday::TimeoutError
        report.add_error("Timeout error", "The connection to the server timed out.")
      rescue Faraday::SSLError
        report.add_error("Unsafe link", "This site's SSL security certificate has expired - it might not be safe for users.")
      rescue Faraday::Error => e
        report.add_error("Unknown issue", "Speak to your technical team: #{e}")
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
