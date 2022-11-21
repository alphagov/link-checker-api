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

      stub_request(:get, "https://www.gov.uk?key[]=value").to_return(status: 200)
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

    context "URI with an unusual format" do
      let(:uri) { "hxxp://www.gov.uk" }
      include_examples "has a problem summary", "Unusual URL"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "URI with supported scheme" do
      let(:uri) { "https://www.gov.uk/ok" }
      include_examples "has no errors"
      include_examples "has no warnings"
    end

    context "Invalid URI which can be normalised" do
      # [] _should_ be percent-encoded, but browsers will accept it not being
      let(:uri) { "https://www.gov.uk?key[]=value" }
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

      before do
        stub_request(:get, "http://www.gov.uk/ok").to_return(
          body: (lambda do |_|
            sleep 5.1
            ""
          end),
        )
      end

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
      before do
        stub_request(:get, uri)
          .to_raise(Faraday::SSLError).then
          .to_return(status: 404)
      end
      # 404 has a higher priority than SSL error, so it'll be the
      # displayed problem summary.
      include_examples "has a problem summary", "Page not found"
      include_examples "has errors"
      include_examples "has warnings"
    end

    context "header with CR/LF character" do
      let(:uri) { "http://www.not-gov.uk/header_with_CRLF_character" }
      before do
        stub_request(:get, uri)
          .to_return(headers: { "Invalid" => "A header containing a carriage return \r character" })
      end

      include_examples "has errors"
      include_examples "has a problem summary", "Page unavailable"
    end

    it "does not recue from other argument error" do
      uri = "http://www.not-gov.uk/raises_argument_error"
      error = ArgumentError.new("something that's nothing to do with headers and carriage return line feed chars")

      stub_request(:get, uri).to_raise(error)

      expect { described_class.new(uri).call }.to raise_error(error)
    end

    context "slow response" do
      let(:uri) { "http://www.not-gov.uk/slow_response" }

      before do
        stub_request(:get, uri).to_return(
          body: (lambda do |_|
            sleep 5.1
            ""
          end),
        )
      end

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

    context "401 status code" do
      let(:uri) { "http://www.not-gov.uk/401" }
      before { stub_request(:get, uri).to_return(status: 401) }
      include_examples "has errors", "401 error (page requires login)"
      include_examples "has no warnings"
    end

    context "403 status code" do
      let(:uri) { "http://www.not-gov.uk/403" }
      before { stub_request(:get, uri).to_return(status: 403) }
      include_examples "has errors", "403 error (page requires login)"
      include_examples "has no warnings"
    end

    context "404 status code" do
      let(:uri) { "http://www.not-gov.uk/404" }
      before { stub_request(:get, uri).to_return(status: 404) }
      include_examples "has errors", "404 error (page not found)"
      include_examples "has no warnings"
    end

    context "410 status code" do
      let(:uri) { "http://www.not-gov.uk/410" }
      before { stub_request(:get, uri).to_return(status: 410) }
      include_examples "has errors", "410 error (page not found)"
      include_examples "has no warnings"
    end

    context "an unspecified 4xx status code" do
      let(:uri) { "http://www.not-gov.uk/418" }
      before { stub_request(:get, uri).to_return(status: 418) }
      include_examples "has errors", "418 error (page is unavailable)"
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
            headers: { "Content-Type" => "text/html" },
          )
      end

      let(:uri) { "http://www.not-gov.uk/mature_content" }
      include_examples "has a problem summary", "Suspicious content"
      include_examples "has warnings"
      include_examples "has no errors"
    end

    context "bypassing the GOV.UK rate limiter" do
      before do
        stub_request(:get, uri)
          .with(headers: { "Rate-Limit-Token": Rails.application.secrets.govuk_rate_limit_token, "Accept-Encoding": "none" })
          .to_return(status: 200)
      end

      let(:uri) { "#{Plek.website_root}/government/document" }

      include_examples "has no errors"
      include_examples "has no warnings"

      it "should set a Rate-Limit-Token" do
        subject

        expect(WebMock).to have_requested(:get, uri)
          .with(headers: { "Rate-Limit-Token": Rails.application.secrets.govuk_rate_limit_token, "Accept-Encoding": "none" })
      end
    end

    context "when calling a url that requires authentication" do
      let(:host) { "www.needsauthentication.co.uk" }
      let(:uri) { "http://#{host}/a/page" }
      let!(:request) do
        stub_request(:get, uri)
          .with(headers: { "Authorization": "Basic #{Base64.encode64(Rails.application.secrets.govuk_basic_auth_credentials)}".strip })
          .to_return(status: 200)
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
