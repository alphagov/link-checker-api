module LinkChecker::UriChecker
  class FileChecker
    attr_reader :report

    def initialize(_uri, _options = {})
      @report = Report.new
    end

    def call
      report.add_error(
        :local_file,
        "Link is to a local file",
        "You have linked this to a file on your computer, it won't be available
        over the internet."
      )

      report
    end
  end
end
