require "rails_helper"

RSpec.describe LinkChecker::UriChecker::HttpChecker do
  let(:uri) { URI("http://example.invalid/") }
  subject { described_class.new(uri) }
  it "should not throw an exception if the response is nil" do
    allow(subject).to receive(:make_request).with(:get).and_return(nil)
    expect { subject.call }.not_to raise_error
  end

  context "a suspicious domain is passed" do
    before { SuspiciousDomain.destroy_all }
    let(:uri) { URI("http://malicious.example.com/foo") }
    subject { described_class.new(uri) }

    it "should not request the URI if it is a suspicious domain" do
      SuspiciousDomain.create!(domain: "malicious.example.com")
      expect(subject).not_to receive(:make_request)
      report = subject.call
      expect(report.problems).to match([LinkChecker::UriChecker::SuspiciousDomain])
    end
  end

  describe "#sanitised_location_header" do
    def response_with_location(location)
      faraday_env = Faraday::Env.from(
        method: :get,
        status: 301,
        response_headers: Faraday::Utils::Headers.new({ "location" => location }),
      )
      response = Faraday::Response.new
      response.finish(faraday_env)
      response
    end

    it "returns a valid header unchanged" do
      location = "/recherche?q=caf%C3%A9"
      expect(subject.send(:sanitised_location_header, response_with_location(location))).to eq(location)
    end

    it "returns nil when there is no location header" do
      expect(subject.send(:sanitised_location_header, response_with_location(nil))).to be_nil
    end

    it "percent-encodes invalid UTF-8 bytes in the header" do
      location = "/recherche?q=caf\xE9".dup.force_encoding(Encoding::UTF_8)
      expect(subject.send(:sanitised_location_header, response_with_location(location))).to eq("/recherche?q=caf%E9")
    end

    it "handles binary-tagged headers, as net/http delivers them" do
      location = "/recherche?q=caf\xE9".dup.force_encoding(Encoding::ASCII_8BIT)
      expect(subject.send(:sanitised_location_header, response_with_location(location))).to eq("/recherche?q=caf%E9")
    end
  end
end
