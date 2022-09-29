require "rails_helper"

RSpec.describe "check path", type: :request do
  include RequestHelper

  let(:uri) { "http://www.example.com" }

  def check_link_path(query_params = {})
    "/check?#{query_params.to_query}"
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
    it "raises a validation error" do
      expect { get check_link_path }.to raise_error(ActiveModel::ValidationError)
    end
  end

  context "when an ok checked uri is requested" do
    let(:link_report) { build_link_report(uri: uri, status: "ok") }

    before do
      create(
        :check,
        link: create(:link, uri: uri),
        completed_at: 1.minute.ago,
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
    let(:warnings) { ["Potentially suspicious top level domain."] }
    let(:link_report) { build_link_report(uri: uri, status: "caution", warnings: warnings) }

    before do
      create(
        :check,
        link: create(:link, uri: uri),
        link_warnings: warnings,
        completed_at: 1.minute.ago,
      )

      get check_link_path(uri: uri)
    end

    include_examples "returns link report"
  end

  context "when a checked uri, that is of status broken, is requested" do
    let(:errors) { ["Has a cyclic redirect."] }
    let(:link_report) { build_link_report(uri: uri, status: "broken", errors: errors) }

    before do
      create(
        :check,
        link: create(:link, uri: uri),
        link_errors: errors,
        completed_at: 1.minute.ago,
      )

      get check_link_path(uri: uri)
    end

    include_examples "returns link report"
  end

  context "when a checked uri was checked outside the `content-within` time" do
    let(:link_report) { build_link_report(uri: uri, status: "pending") }

    before do
      create(
        :check,
        link: create(:link, uri: uri),
        completed_at: 10.minutes.ago,
        created_at: 11.minutes.ago,
      )

      get check_link_path(uri: uri, checked_within: 5.minutes.to_i)
    end

    include_examples "returns link report"
  end

  context "when an unchecked uri is requested with synchronous = true" do
    let(:uri) { "http://www.example.com/page" }
    let(:link_report) { build_link_report(uri: uri, status: "ok") }

    before do
      stub_request(:get, uri).to_return(status: 200)

      get check_link_path(uri: uri, synchronous: "true")
    end

    include_examples "returns link report"
  end

  context "when an uri is in progress with synchronous = true" do
    let(:uri) { "http://www.example.com/page" }
    let(:link_report) { build_link_report(uri: uri, status: "ok") }

    before do
      create(:check, link: create(:link, uri: uri))

      stub_request(:get, uri).to_return(status: 200)

      get check_link_path(uri: uri, synchronous: true)
    end

    include_examples "returns link report"
  end

  context "when the user is not authenticated" do
    around do |example|
      ClimateControl.modify(GDS_SSO_MOCK_INVALID: "1") { example.run }
    end

    it "returns an unauthorized response" do
      get check_link_path(uri: "http://www.example.com/page", synchronous: true)
      expect(response).to be_unauthorized
    end
  end
end
