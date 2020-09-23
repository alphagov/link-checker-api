module LinkChecker::UriChecker
  class Problem
    attr_reader :type, :message, :suggested_fix, :summary, :priority

    def initialize(type:, summary:, message:, suggested_fix: nil, from_redirect:, **options)
      @type = type
      @from_redirect = from_redirect
      @text_args = options

      @summary = get_string(summary)
      @message = get_string(message)
      @suggested_fix = get_string(suggested_fix)

      @priority = PRIORITIES.index(self.class.name.demodulize.to_sym)

      raise "Unknown priority." if priority.nil?
    end

  private

    attr_reader :from_redirect, :text_args

    def get_string(symbol)
      return nil if symbol.nil?

      symbols = [
        :"#{symbol}.#{from_redirect ? "redirect" : "singular"}",
        symbol,
      ]

      string = symbols
        .map { |sym| I18n.t(sym, **text_args.merge(default: nil)) }
        .compact
        .first

      raise "Invalid locale symbol: #{symbol}" if string.nil?

      string
    end

    PRIORITIES = %i[
      MissingUriScheme
      InvalidUri
      ContactDetails
      UnusualUrl
      NotAvailableOnline
      NoHost
      FaradayError
      PageNotFound
      PageRequiresLogin
      PageIsUnavailable
      PageRespondsWithError
      PageRespondsUnusually
      TooManyRedirects
      RedirectLoop
      TooManyRedirectsSlowly
      CredentialsInUri
      SuspiciousTld
      SlowResponse
      PageWithRating
      PageContainsThreat
      SecurityProblem
    ].freeze
  end
end
