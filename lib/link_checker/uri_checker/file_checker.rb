module LinkChecker::UriChecker
  class NotAvailableOnline < Error
    def initialize(options = {})
      super(summary: :not_available_online, message: :links_to_file_on_computer, **options)
    end
  end

  class FileChecker < Checker
    def call
      add_problem(NotAvailableOnline.new(from_redirect: from_redirect?))
    end
  end
end
