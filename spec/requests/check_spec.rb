require "rails_helper"

RSpec.describe "check path", type: :request do
  let(:uri) { "http://www.example.com" }

  def check_link_path(query_params = {})
    "/check?#{query_params.to_query}"
  end

  def build_link_report(params)
    {
      "uri"       => params.fetch(:uri, anything),
      "status"    => params.fetch(:status, anything),
      "checked"   => params.fetch(:checked, anything),
      "errors"    => params.fetch(:errors, {}),
      "warnings"  => params.fetch(:warnings, {}),
    }
  end

  shared_examples "returns link report" do
    it "returns 200" do
      expect(response).to have_http_status(200)
    end

    it "returns a link report" do
      json = JSON.parse(response.body)
      expect(json).to match(link_report)
    end
  end

  context "when no uri is requested" do
    before { get check_link_path }

    it "returns 400" do
      expect(response).to have_http_status(400)
    end
  end

  context "when an ok checked uri is requested" do
    let(:link_report) { build_link_report(uri: uri, status: "ok") }

    before do
      FactoryGirl.create(
        :check,
        link: FactoryGirl.create(:link, uri: uri),
        ended_at: 1.minute.ago,
      )

      get check_link_path(uri: uri)
    end

    include_examples "returns link report"
  end

  context "when an unchecked uri is requested" do
    let(:link_report) { build_link_report(uri: uri, status: "pending") }

    before { get check_link_path(uri: uri) }

    include_examples "returns link report"
  end

  context "when a checked uri, that is of status caution, is requested" do
    let(:warnings) do
      {
        "risky_tld" => ["Potentially suspicious top level domain."],
      }
    end
    let(:link_report) { build_link_report(uri: uri, status: "caution", warnings: warnings) }

    before do
      FactoryGirl.create(
        :check,
        link: FactoryGirl.create(:link, uri: uri),
        link_warnings: warnings,
        ended_at: 1.minute.ago,
      )

      get check_link_path(uri: uri)
    end

    include_examples "returns link report"
  end

  context "when a checked uri, that is of status broken, is requested" do
    let(:errors) do
      {
        "cyclic_redirect" => ["Has a cyclic redirect."],
      }
    end
    let(:link_report) { build_link_report(uri: uri, status: "broken", errors: errors) }

    before do
      FactoryGirl.create(
        :check,
        link: FactoryGirl.create(:link, uri: uri),
        link_errors: errors,
        ended_at: 1.minute.ago,
      )

      get check_link_path(uri: uri)
    end

    include_examples "returns link report"
  end

  context "when a checked uri was checked outside the `content-within` time" do
    let(:link_report) { build_link_report(uri: uri, status: "pending") }

    before do
      FactoryGirl.create(
        :check,
        link: FactoryGirl.create(:link, uri: uri),
        ended_at: 10.minute.ago,
      )

      get check_link_path(uri: uri, "checked-within": 5.minutes.to_i)
    end

    include_examples "returns link report"
  end

  context "when an unchecked uri is requested with synchronous = true" do
    let(:uri) { "http://www.example.com/page" }
    let(:link_report) { build_link_report(uri: uri, status: "ok") }

    before do
      stub_request(:head, uri).to_return(status: 200)
      stub_request(:post, "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=test")
        .to_return(status: 200, body: "{}")

      get check_link_path(uri: uri, synchronous: "true")
    end

    include_examples "returns link report"
  end
end