class LinkCheck
  attr_reader :uri, :report

  def initialize(uri)
    @uri = uri
    @report = UriChecker::Report.new
  end

  def call
    report.merge(UriChecker::ValidUri.new.call(uri))
  end
end
