module HistoricalLinkChecker::Error
  class RecurredForMoreThanThreeDaysLinkError < ::LinkChecker::UriChecker::Error
    def initialize(options = {})
      super(
        from_redirect: false,
        summary: :recurring_error,
        message: :recurred_for_more_than_three_days,
        **options
      )
    end
  end
end
