module LinkChecker::UriChecker
  class FileChecker < Checker
    def call
      add_error(
        summary: "Not available online",
        message: {
          singular: "This links to a file on your computer and won't open for users",
          redirect: "This redirects to an invalid link.",
        }
      )
    end
  end
end
