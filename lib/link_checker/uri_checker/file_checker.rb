module LinkChecker::UriChecker
  class FileChecker < Checker
    def call
      add_error(
        summary: :not_available_online,
        message: :links_to_file_on_computer,
      )
    end
  end
end
