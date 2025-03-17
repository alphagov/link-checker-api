require "rails_helper"

RSpec.describe LinkChecker::UriChecker::HttpChecker do
  let(:uri) { URI("http://example.invalid/") }
  subject { described_class.new(uri) }
  it "should not throw an exception if the response is nil" do
    allow(subject).to receive(:make_request).with(:get).and_return(nil)
    expect { subject.call }.not_to raise_error
  end

  context "a suspicious domain is passed" do
    let(:uri) { URI("http://malicious.example.com/foo") }
    subject { described_class.new(uri) }
    it "should not request the URI if it is a suspicious domain" do
      expect(subject).not_to receive(:make_request)
      report = subject.call
      expect(report.problems).to match([LinkChecker::UriChecker::SuspiciousDomain])
    end
  end
end
