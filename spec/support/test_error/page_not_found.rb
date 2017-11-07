module TestError
  class PageNotFound < ::LinkChecker::UriChecker::Error
    def initialize(options = {})
      super(summary: :page_not_found, message: :page_was_not_found, suggested_fix: :find_content_now, **options)
    end
  end
end
