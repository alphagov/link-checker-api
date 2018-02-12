require "rails_helper"

RSpec.describe LinkChecker do
  context "for different kinds of URIs" do
    subject { described_class.new(uri).call }

    shared_examples "has no errors" do
      it "should have no errors" do
        expect(subject.errors).to be_empty
      end
    end

    shared_examples "has errors" do
      it "should have errors" do
        expect(subject.errors).to_not be_empty
      end
    end

    shared_examples "has no warnings" do
      it "should have no warnings" do
        expect(subject.warnings).to be_empty
      end
    end

    shared_examples "has warnings" do
      it "should have warnings" do
        expect(subject.warnings).to_not be_empty
      end
    end

    shared_examples "has a problem summary" do |summary|
      it "should have a problem summary of #{summary}" do
        expect(subject.problem_summary).to eq(summary)
      end
    end

    before do
      stub_request(:get, "https://www.gov.uk/ok").to_return(status: 200)

      stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
        .to_return(status: 200, body: "{}")
    end

    context "invalid URI" do
      let(:uri) { "this is not a URI" }
      include_examples "has a problem summary", "Invalid URL"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "URI with no scheme" do
      let(:uri) { "//test/test" }
      include_examples "has a problem summary", "Invalid URL"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "URI with no host" do
      let(:uri) { "http:///" }
      include_examples "has a problem summary", "Invalid URL"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "URI with an unsupported scheme" do
      let(:uri) { "mailto:test@test" }
      include_examples "has a problem summary", "Contact details"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "URI with supported scheme" do
      let(:uri) { "https://www.gov.uk/ok" }
      include_examples "has no errors"
      include_examples "has no warnings"
    end

    context "TLD is risky" do
      let(:uri) { "https://www.gov.xxx" }
      before { stub_request(:get, uri).to_return(status: 200) }
      include_examples "has a problem summary", "Suspicious Destination"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "there are credentials in the URI" do
      let(:uri) { "https://username:password@www.gov.uk/ok" }
      include_examples "has a problem summary", "Login details in URL"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "with multiple problems" do
      let(:uri) { "http://username:password@www.gov.uk/ok" }
      before { stub_request(:get, "http://www.gov.uk/ok").to_return(body: lambda { |_| sleep 5.1; "" }) }
      include_examples "has a problem summary", "Login details in URL"
      include_examples "has warnings"
      include_examples "has no errors"

      it "has no suggested_fix" do
        expect(subject.suggested_fix).to be_nil
      end
    end

    context "cannot connect to page" do
      let(:uri) { "http://www.not-gov.uk/connection_failed" }
      before { stub_request(:get, uri).to_raise(Faraday::ConnectionFailed) }
      include_examples "has a problem summary", "Website unavailable"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "SSL error" do
      let(:uri) { "http://www.not-gov.uk/ssl_error" }
      before { stub_request(:get, uri).to_raise(Faraday::SSLError) }
      include_examples "has a problem summary", "Security Error"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "slow response" do
      let(:uri) { "http://www.not-gov.uk/slow_response" }
      before { stub_request(:get, uri).to_return(body: lambda { |_| sleep 5.1; "" }) }
      include_examples "has a problem summary", "Slow page"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "request timed out" do
      let(:uri) { "http://www.not-gov.uk/timeout" }
      before { stub_request(:get, uri).to_raise(Faraday::TimeoutError) }
      include_examples "has a problem summary", "Website unavailable"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "4xx status code" do
      let(:uri) { "http://www.not-gov.uk/404" }
      before { stub_request(:get, uri).to_return(status: 404) }
      include_examples "has errors", "404 error (page not found)"
      include_examples "has no warnings"
    end

    context "5xx status code" do
      let(:uri) { "http://www.not-gov.uk/500" }
      before { stub_request(:get, uri).to_return(status: 500) }
      include_examples "has errors", "500 (server error)"
      include_examples "has no warnings"
    end

    context "non-200 status code" do
      let(:uri) { "http://www.not-gov.uk/201" }
      before { stub_request(:get, uri).to_return(status: 201) }
      include_examples "has a problem summary", "Page unavailable"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "too many redirects" do
      let(:uri) { "http://www.not-gov.uk/too_many_redirects" }
      before do
        stub_request(:get, uri)
          .to_return(status: 301, headers: { "Location" => "/too_many_redirects_1" })

        20.times do |i|
          stub_request(:get, "http://www.not-gov.uk/too_many_redirects_#{i}")
            .to_return(status: 301, headers: { "Location" => "/too_many_redirects_#{i + 1}" })
        end
      end
      include_examples "has a problem summary", "Broken Redirect"
      include_examples "has errors"
      include_examples "has warnings"
    end

    context "multiple redirects" do
      before do
        stub_request(:get, uri)
          .to_return(status: 301, headers: { "Location" => "/multiple_redirects_1" })

        2.times do |i|
          stub_request(:get, "http://www.not-gov.uk/multiple_redirects_#{i}")
            .to_return(status: 301, headers: { "Location" => "/multiple_redirects_#{i + 1}" })
        end

        stub_request(:get, "http://www.not-gov.uk/multiple_redirects_2")
          .to_return(status: 301, headers: { "Location" => "https://www.gov.uk/ok" })
      end

      let(:uri) { "http://www.not-gov.uk/multiple_redirects" }
      include_examples "has a problem summary", "Bad Redirect"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "cyclic redirects" do
      before do
        stub_request(:get, "http://www.not-gov.uk/cyclic")
          .to_return(status: 301, headers: { "Location" => "/cyclic1" })

        stub_request(:get, "http://www.not-gov.uk/cyclic1")
          .to_return(status: 301, headers: { "Location" => "/cyclic2" })

        stub_request(:get, "http://www.not-gov.uk/cyclic2")
          .to_return(status: 301, headers: { "Location" => "/cyclic" })
      end

      let(:uri) { "http://www.not-gov.uk/cyclic" }
      include_examples "has a problem summary", "Broken Redirect"
      include_examples "has warnings"
      include_examples "has errors"
    end

    context "a local file" do
      let(:uri) { "file://file.txt" }
      include_examples "has a problem summary", "Not available online"
      include_examples "has errors"
      include_examples "has no warnings"
    end

    context "meta rating suggests mature content" do
      before do
        stub_request(:get, "http://www.not-gov.uk/mature_content")
          .to_return(status: 200, headers: { "Content-Type" => "text/html" })

        stub_request(:get, "http://www.not-gov.uk/mature_content")
          .to_return(
            status: 200,
            body: "<meta name=rating value=mature>",
            headers: { "Content-Type" => "text/html" }
          )
      end

      let(:uri) { "http://www.not-gov.uk/mature_content" }
      include_examples "has a problem summary", "Suspicious content"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "bypassing the GOV.UK rate limiter" do
      before do
        stub_request(:get, uri).
          with(headers: { "Rate-Limit-Token": Rails.application.secrets.govuk_rate_limit_token, "Accept-Encoding": "none" }).
          to_return(status: 200)
      end

      let(:uri) { "#{Plek.new.website_root}/government/document" }

      include_examples "has no errors"
      include_examples "has no warnings"

      it 'should set a Rate-Limit-Token' do
        subject

        expect(WebMock).to have_requested(:get, uri).
          with(headers: { "Rate-Limit-Token": Rails.application.secrets.govuk_rate_limit_token, "Accept-Encoding": "none" })
      end
    end

    context "a URL detected by Google Safebrowser API" do
      let(:uri) { "http://malware.testing.google.test/testing/malware/" }
      before do
        stub_request(:get, uri).to_return(status: 200)
        stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
          .to_return(status: 200, body: { matches: [{ threatType: "MALWARE" }] }.to_json)
      end
      include_examples "has a problem summary", "Suspicious content"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "Google Safebrowser API on a gov.uk url" do
      let(:uri) { "http://www.dev.gov.uk/malware.testing.google.test/testing/malware/" }
      before do
        stub_request(:get, uri).to_return(status: 200)
      end
      let(:request) do
        stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
      end

      include_examples "has no warnings"
      include_examples "has no errors"
      it "should not make a request" do
        subject

        expect(request).to_not have_been_requested
      end
    end

    context "Google Safebrowser API on a gov.uk upload url" do
      let(:uri) { "http://www.dev.gov.uk/government/uploads" }
      before do
        stub_request(:get, uri).to_return(status: 200)
      end
      let(:request) do
        stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
          .to_return(status: 200, body: "{}")
      end

      include_examples "has no warnings"
      include_examples "has no errors"
      it "should make a request" do
        subject

        expect(request).to have_been_requested
      end
    end

    context "Google Safebrowser API on an asset-manager upload url" do
      let(:uri) { "https://assets.publishing.service.gov.uk/media/" }
      before do
        stub_request(:get, uri).to_return(status: 200)
      end
      let(:request) do
        stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
          .to_return(status: 200, body: "{}")
      end

      include_examples "has no warnings"
      include_examples "has no errors"
      it "should make a request" do
        subject

        expect(request).to have_been_requested
      end
    end

    context "Google Safebrowser API returns an error" do
      let(:uri) { "http://www.gov.uk/government/uploads" }
      before do
        stub_request(:get, uri).to_return(status: 200)
      end
      let!(:request) do
        stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
          .to_return(status: 500, body: "an error", headers: { 'X-Foo' => 'bar' })
      end

      include_examples "has no warnings"
      include_examples "has no errors"
      it "should log the error to Sentry" do
        expect(GovukError).to receive(:notify)
          .with("Unable to talk to Google Safebrowsing API!",
            extra: {
              status: 500,
              body: 'an error',
              headers: { 'X-Foo' => 'bar' },
            })

        subject

        expect(request).to have_been_requested
      end
    end

    context "Google Safebrowser API rate limits the request" do
      let(:uri) { "http://www.gov.uk/government/uploads" }
      before do
        stub_request(:get, uri).to_return(status: 200)
      end
      let!(:request) do
        stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
          .to_return(status: 429, body: "an error", headers: { 'X-Foo' => 'bar' })
      end

      include_examples "has no warnings"
      include_examples "has no errors"
      it "should increment the counter in statsd" do
        expect(GovukStatsd).to receive(:increment).with("safebrowsing.rate_limited")

        subject

        expect(request).to have_been_requested
      end
    end

    context "when calling a url that requires authentication" do
      let(:host) { "www.needsauthentication.co.uk" }
      let(:uri) { "http://#{host}/a/page" }
      let!(:request) do
        stub_request(:get, uri).
          with(headers: { "Authorization": "Basic #{Base64.encode64(Rails.application.secrets.govuk_basic_auth_credentials)}".strip }).
          to_return(status: 200)
      end

      before do
        LinkCheckerApi.hosts_with_basic_authorization[host.to_s] = Rails.application.secrets.govuk_basic_auth_credentials
      end

      it "should add basic auth" do
        subject

        expect(request).to have_been_requested
      end
    end
  end
end
