require "rails_helper"
# rubocop:disable BlockLength
RSpec.describe "monitor path", type: :request do
  shared_examples "returns a report" do
    it "returns 200" do
      expect(response).to have_http_status(200)
    end

    it "returns a monitor report" do
      json = JSON.parse(response.body)

      expect(json).to match("id" => ResourceMonitor.last.id)
    end
  end

  describe "POST /monitor" do
    let(:organisation) { "testorg" }
    let(:params) do
      {
        links: ["https://example.com/a", "https://example.com/b"],
        app: "govuk",
        reference: "test:1",
        organisation: organisation
      }
    end

    context "when valid" do
      before do
        post "/monitor", params: params.to_json, headers: { "Content-Type" => "application/json" }
      end

      include_examples "returns a report"

      it "should create a ResourceMonitor with a organisation" do
        expect(ResourceMonitor.last.organisation).to eq(organisation)
      end
    end

    context "when invalid" do
      subject do
        post "/monitor", params: params.to_json, headers: { "Content-Type" => "application/json" }
      end

      let(:params) do
        {
          links: ["https://example.com/a", "https://example.com/b"],
          service: nil
        }
      end

      it "returns an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
# rubocop:enable BlockLength
