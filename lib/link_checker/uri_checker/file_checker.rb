module LinkChecker::UriChecker
  class FileChecker
    attr_reader :report

    def initialize(_uri, _options = {})
      @report = Report.new
    end

    def call
      report.add_error("Local file", "Link is to a local file.")
      report
    end
  end
end
