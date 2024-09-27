require "rails_helper"

RSpec.describe "/batch endpoint" do
  include ActiveJob::TestHelper
  include RequestHelper

  shared_examples "returns batch report" do |status_code = 202|
    it "returns #{status_code}" do
      expect(response).to have_http_status(status_code)
    end

    it "returns a batch report" do
      json = JSON.parse(response.body)
      expect(json).to match(batch_report)
    end
  end

  describe "POST /batch" do
    context "when creating a batch of links that haven't been checked" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      let(:batch_request) { build_batch_request(uris: [uri_a, uri_b]) }
      let(:batch_report) do
        build_batch_report(
          status: "in_progress",
          links: [
            { uri: uri_a, status: "pending" },
            { uri: uri_b, status: "pending" },
          ],
        )
      end

      before do
        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type" => "application/json" }
      end

      include_examples "returns batch report"

      it "creates a job" do
        expect(CheckJob.jobs.size).to eq(2)
      end
    end

    context "when creating a batch of links with a secret key" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }
      let(:webhook_secret_token) { "this is a secret key" }

      let(:batch_request) { build_batch_request(uris: [uri_a, uri_b], webhook_secret_token:) }

      before do
        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type" => "application/json" }
      end

      it "creates a batch with a secret key" do
        expect(Batch.last.webhook_secret_token).to eq(webhook_secret_token)
      end
    end

    context "when creating a batch of links and one of them is empty" do
      let(:uri_a) { "" }
      let(:uri_b) { "http://example.com/b" }

      let(:batch_request) { build_batch_request(uris: [uri_a, uri_b]) }
      let(:batch_report) do
        build_batch_report(
          status: "in_progress",
          links: [
            { uri: uri_b, status: "pending" },
          ],
        )
      end

      before do
        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type" => "application/json" }
      end

      include_examples "returns batch report"
    end

    context "with many links, it retains the ordering" do
      let(:uris) do
        1000.times.map { |i| "http://example.com/#{i}" }
      end

      let(:batch_request) { build_batch_request(uris:) }
      let(:batch_report) do
        build_batch_report(
          status: "in_progress",
          links: uris.map { |uri| { uri:, status: "pending" } },
        )
      end

      before do
        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type" => "application/json" }
      end

      include_examples "returns batch report"
    end

    context "when creating a batch where some of the links have been checked" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      let(:batch_request) { build_batch_request(uris: [uri_a, uri_b]) }
      let(:batch_report) do
        build_batch_report(
          status: "in_progress",
          links: [
            { uri: uri_a, status: "ok" },
            { uri: uri_b, status: "pending" },
          ],
        )
      end

      before do
        create(
          :check,
          link: create(:link, uri: uri_a),
          completed_at: 1.minute.ago,
        )

        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type": "application/json" }
      end

      include_examples "returns batch report"
    end

    context "when creating a batch and all the links have been checked" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      let(:batch_request) { build_batch_request(uris: [uri_a, uri_b]) }
      let(:batch_report) do
        build_batch_report(
          status: "completed",
          links: [
            { uri: uri_a, status: "ok" },
            { uri: uri_b, status: "ok" },
          ],
        )
      end

      before do
        create(
          :check,
          link: create(:link, uri: uri_a),
          completed_at: 1.minute.ago,
        )

        create(
          :check,
          link: create(:link, uri: uri_b),
          completed_at: 1.minute.ago,
        )

        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type": "application/json" }
      end

      include_examples "returns batch report", 201
    end

    context "when creating a batch with no links" do
      let(:batch_request) { build_batch_request(uris: []) }

      it "returns 400" do
        expect { post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" } }
          .to raise_error(ActiveModel::ValidationError)
      end
    end

    context "when creating a batch with too many links" do
      let(:batch_request) { build_batch_request(uris: ["http://example.com"] * 5001) }

      it "returns 400" do
        expect { post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" } }
          .to raise_error(ActiveModel::ValidationError)
      end
    end

    context "when creating a batch and specifying links were checked_within a time" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      let(:batch_request) do
        build_batch_request(
          uris: [uri_a, uri_b],
          checked_within: 600,
        )
      end

      let(:batch_report) do
        build_batch_report(
          status: "in_progress",
          links: [
            { uri: uri_a, status: "ok" },
            { uri: uri_b, status: "pending" },
          ],
        )
      end

      before do
        create(
          :check,
          link: create(:link, uri: uri_a),
          completed_at: 5.minutes.ago,
          created_at: 5.minutes.ago,
        )

        create(
          :check,
          link: create(:link, uri: uri_b),
          completed_at: 20.minutes.ago,
          created_at: 20.minutes.ago,
        )

        post "/batch",
             params: batch_request.to_json,
             headers: { "Content-Type": "application/json" }
      end

      include_examples "returns batch report"
    end

    context "when creating a batch and specifying a callback url" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }
      let(:webhook_uri) { "http://my-host.com/hook" }
      let!(:stubbed_request) { stub_request(:post, webhook_uri) }

      let(:batch_request) do
        build_batch_request(
          uris: [uri_a, uri_b],
          webhook_uri:,
        )
      end

      context "and the links have already been checked" do
        let(:batch_report) do
          build_batch_report(
            status: "completed",
            links: [
              { uri: uri_a, status: "ok" },
              { uri: uri_b, status: "ok" },
            ],
          )
        end

        before do
          create(
            :check,
            link: create(:link, uri: uri_a),
            completed_at: 1.minute.ago,
          )

          create(
            :check,
            link: create(:link, uri: uri_b),
            completed_at: 1.minute.ago,
          )

          Sidekiq::Testing.inline! do
            post "/batch",
                 params: batch_request.to_json,
                 headers: { "Content-Type": "application/json" }
          end
        end

        it "posts a request to the webhook_uri" do
          expect(stubbed_request).to have_been_requested
        end

        include_examples "returns batch report", 201
      end

      context "but the links haven't been checked before" do
        let(:batch_report) do
          build_batch_report(
            status: "in_progress",
            links: [
              { uri: uri_a, status: "pending" },
              { uri: uri_b, status: "pending" },
            ],
          )
        end

        before do
          post "/batch",
               params: batch_request.to_json,
               headers: { "Content-Type": "application/json" }
        end

        it "doesn't post a request to the webhook_uri" do
          expect(stubbed_request).not_to have_been_requested
        end

        include_examples "returns batch report"
      end
    end

    context "when the user is not authenticated" do
      around do |example|
        ClimateControl.modify(GDS_SSO_MOCK_INVALID: "1") { example.run }
      end

      it "returns an unauthorized response" do
        post "/batch", params: {}.to_json
        expect(response).to be_unauthorized
      end
    end
  end

  describe "GET /batch/:id" do
    context "when requesting a batch that doesn't exist" do
      it "returns 404" do
        get "/batch/432"
        expect(response).to be_not_found
      end
    end

    context "when requesting a batch that has completed" do
      let(:batch_id) { 12 }
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      before do
        create(
          :batch,
          id: batch_id,
          checks: [
            create(
              :check,
              link: create(:link, uri: uri_a),
              completed_at: 1.minute.ago,
            ),
            create(
              :check,
              link: create(:link, uri: uri_b),
              completed_at: 1.minute.ago,
            ),
          ],
        )

        get "/batch/#{batch_id}"
      end

      let(:batch_report) do
        build_batch_report(
          id: batch_id,
          status: "completed",
          links: [
            { uri: uri_a, status: "ok" },
            { uri: uri_b, status: "ok" },
          ],
        )
      end

      include_examples "returns batch report", 200
    end

    context "when requesting a batch that is in progress" do
      let(:batch_id) { 5 }
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      before do
        create(
          :batch,
          id: batch_id,
          checks: [
            create(
              :check,
              link: create(:link, uri: uri_a),
            ),
            create(
              :check,
              link: create(:link, uri: uri_b),
            ),
          ],
        )

        get "/batch/#{batch_id}"
      end

      let(:batch_report) do
        build_batch_report(
          id: batch_id,
          status: "in_progress",
          links: [
            { uri: uri_a, status: "pending" },
            { uri: uri_b, status: "pending" },
          ],
        )
      end

      include_examples "returns batch report", 200
    end

    context "when the user is not authenticated" do
      around do |example|
        ClimateControl.modify(GDS_SSO_MOCK_INVALID: "1") { example.run }
      end

      it "returns an unauthorized response" do
        get "/batch/123", params: {}.to_json
        expect(response).to be_unauthorized
      end
    end
  end
end
