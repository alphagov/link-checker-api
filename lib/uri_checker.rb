require "uri"

module UriChecker
  class Report
    attr_reader :errors, :warnings

    def initialize(errors: nil, warnings: nil)
      @errors = errors || Hash.new { |hash, key| hash[key] = [] }
      @warnings = warnings || Hash.new { |hash, key| hash[key] = [] }
    end

    def merge!(other)
      errors.merge!(other.errors) { |key, oldval, newval| oldval | newval }
      warnings.merge!(other.warnings) { |key, oldval, newval| oldval | newval }
    end

    def has_errors?
      !errors.empty?
    end
  end

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
        report.warnings[:no_scheme] << "No scheme given."
      elsif HTTP_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge!(HttpChecker.new(parsed_uri, options).call)
      elsif FILE_URI_SCHEMES.include?(parsed_uri.scheme)
        report.merge!(FileChecker.new(parsed_uri, options).call)
      else
        report.warnings[:unsupported_scheme] << "Unsupported scheme."
      end

      report
    rescue URI::InvalidURIError
      report.errors[:uri_invalid] << "Invalid URI"
      report
    end
  end

  class HttpChecker
    INVALID_TOP_LEVEL_DOMAINS = %w(xxx adult)
    REDIRECT_LIMIT = 10
    REDIRECT_WARNING = 2
    TIMEOUT = 5
    SLOW_RESPONSE_TIME = 2

    attr_reader :uri, :redirect_history, :report

     def initialize(uri, redirect_history: [])
      @uri = uri
      @redirect_history = redirect_history
      @report = Report.new
    end

    def call
      check_redirects
      return report if report.has_errors?

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
      report.errors[:too_many_redirects] << "Too many redirects." if redirect_history.length >= REDIRECT_LIMIT
      report.errors[:cyclic_redirects] << "Has a cyclic redirect." if redirect_history.include?(uri)
      report.warnings[:multiple_redirects] << "Multiple redirects." if redirect_history.length == REDIRECT_WARNING
    end

    def check_top_level_domain
      tld = uri.host.split(".").last
      if INVALID_TOP_LEVEL_DOMAINS.include?(tld)
        report.warnings[:risky_tld] << "Potentially suspicious top level domain."
      end
    end

    def check_credentials
      if uri.user.present? || uri.password.present?
        report.warnings[:credentials_in_uri] << "Credentials in URI"
      end
    end

    def check_head_request
      start_time = Time.now
      response = make_request(:head)
      end_time = Time.now
      response_time = end_time - start_time

      report.warnings[:slow_response] << "Slow response time" if response_time > SLOW_RESPONSE_TIME

      return response if report.has_errors?

      if response.status >= 400 && response.status < 500
        report.errors[:http_client_error] << "Received 4xx response"
      elsif response.status >= 500 && response.status < 600
        report.errors[:http_server_error] << "Received 5xx response"
      end

      report.warnings[:http_non_200] << "Page not available." unless response.status == 200
      response
    end

    def check_get_request
      response = make_request(:get)
      return unless response

      page = Nokogiri::HTML(response.body)
      rating = page.css("meta[name=rating]")[0]["value"]
      if %w(restricted mature).include?(rating)
        report.warnings[:meta_rating] << "Page suggests it contains mature content."
      end
    end

    def check_google_safebrowsing
      api_key = Rails.application.secrets.google_api_key

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

      data = JSON.parse(response.body)
      if data.include?("matches") && data["matches"]
        report.warnings[:google_safebrowsing] << "Google Safebrowsing has detected a threat."
      end
    end

    def make_request(method)
      begin
        response = run_connection_request(method)

        if response.status >= 300 && response.status < 400
          target_uri = uri + response.headers["location"]
          subreport = ValidUri
            .new(redirect_history: redirect_history + [uri])
            .call(target_uri.to_s)
          report.merge!(subreport)
        end

        response
      rescue Faraday::ConnectionFailed
        report.errors[:cant_connect] << "Connection failed"
      rescue Faraday::TimeoutError
        report.errors[:timeout] << "Timeout Error"
      rescue Faraday::SSLError
        report.errors[:ssl_configuration] << "SSL Error"
      rescue Faraday:: Error => e
        report.errors[:unknown_http_error] << e.class.to_s
      end
    end

    def run_connection_request(method)
      connection.run_request(method, uri, nil, nil) do |request|
        request.options[:timeout] = TIMEOUT
        request.options[:open_timeout] = TIMEOUT
      end
    end

    def connection
      @connection ||= Faraday.new(headers: { accept_encoding: "none" }) do |faraday|
        faraday.adapter Faraday.default_adapter
      end
    end
  end

  class FileChecker
    attr_reader :report

    def initialize(uri, options = {})
      @report = Report.new
    end

    def call
      report.errors[:local_file] << "Link is to a local file."
      report
    end
  end
end
