module HistoricalLinkChecker::Error
  class RecurredForMoreThanOneWeekLinkError < ::LinkChecker::UriChecker::Error
    def initialize(options = {})
      super(
        from_redirect: false,
        summary: :recurring_error,
        message: :recurred_for_more_than_one_week,
        **options
      )
    end
  end
end
