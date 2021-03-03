require "rails_helper"

RSpec.describe LinkChecker::UriChecker::HttpChecker do
  let(:uri) { URI("http://example.invalid/") }
  subject { described_class.new(uri) }
  it "should not throw an exception if the response is nil" do
    allow(subject).to receive(:make_request).with(:get).and_return(nil)
    expect { subject.call }.not_to raise_error
  end
end
