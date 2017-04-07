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
          ]
        )
      end

      before { post "/batch", params: batch_request.to_json, headers: { "Content-Type" => "application/json" } }

      include_examples "returns batch report"

      it "creates a job" do
        expect(CheckJob).to have_been_enqueued.exactly(2)
      end
    end

    context "when creating a batch where some of the links have been checked" do
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      let(:batch_request) { build_batch_request(uris: [uri_a, uri_b]) }
      let(:batch_report) do
        build_batch_report(
          status: "in_progress",
          links: [
            {uri: uri_a, status: "ok"},
            {uri: uri_b, status: "pending"},
          ]
        )
      end

      before do
        FactoryGirl.create(
          :check,
          link: FactoryGirl.create(:link, uri: uri_a),
          completed_at: 1.minute.ago,
        )

        post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" }
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
            {uri: uri_a, status: "ok"},
            {uri: uri_b, status: "ok"},
          ]
        )
      end

      before do
        FactoryGirl.create(
          :check,
          link: FactoryGirl.create(:link, uri: uri_a),
          completed_at: 1.minute.ago,
        )

        FactoryGirl.create(
          :check,
          link: FactoryGirl.create(:link, uri: uri_b),
          completed_at: 1.minute.ago,
        )

        post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" }
      end

      include_examples "returns batch report", 201
    end

    context "when creating a batch with no links" do
      let(:batch_request) { build_batch_request(uris: []) }

      before { post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" } }

      it "returns 400" do
        expect(response).to have_http_status(400)
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
          ]
        )
      end

      before do
        FactoryGirl.create(
          :check,
          link: FactoryGirl.create(:link, uri: uri_a),
          completed_at: 5.minute.ago,
          created_at: 5.minute.ago,
        )

        FactoryGirl.create(
          :check,
          link: FactoryGirl.create(:link, uri: uri_b),
          completed_at: 20.minute.ago,
          created_at: 20.minute.ago,
        )

        post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" }
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
          webhook_uri: webhook_uri,
        )
      end

      context "and the links have already been checked" do
        let(:batch_report) do
          build_batch_report(
            status: "completed",
            links: [
              {uri: uri_a, status: "ok"},
              {uri: uri_b, status: "ok"},
            ]
          )
        end

        before do
          FactoryGirl.create(
            :check,
            link: FactoryGirl.create(:link, uri: uri_a),
            completed_at: 1.minute.ago,
          )

          FactoryGirl.create(
            :check,
            link: FactoryGirl.create(:link, uri: uri_b),
            completed_at: 1.minute.ago,
          )

          perform_enqueued_jobs do
            post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" }
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
              {uri: uri_a, status: "pending"},
              {uri: uri_b, status: "pending"},
            ]
          )
        end

        before { post "/batch", params: batch_request.to_json, headers: { "Content-Type": "application/json" } }

        it "doesn't post a request to the webhook_uri" do
          expect(stubbed_request).not_to have_been_requested
        end

        include_examples "returns batch report"
      end
    end
  end

  describe "GET /batch/:id" do
    context "when requesting a batch that doesn't exist" do
      before { get "/batch/432" }

      it "returns 404" do
        expect(response).to have_http_status(404)
      end
    end

    context "when requesting a batch that has completed" do
      let(:batch_id) { 12 }
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      before do
        FactoryGirl.create(
          :batch,
          id: batch_id,
          checks: [
            FactoryGirl.create(
              :check,
              link: FactoryGirl.create(:link, uri: uri_a),
              completed_at: 1.minute.ago
            ),
            FactoryGirl.create(
              :check,
              link: FactoryGirl.create(:link, uri: uri_b),
              completed_at: 1.minute.ago
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
          ]
        )
      end

      include_examples "returns batch report", 200
    end

    context "when requesting a batch that is in progress" do
      let(:batch_id) { 5 }
      let(:uri_a) { "http://example.com/a" }
      let(:uri_b) { "http://example.com/b" }

      before do
        FactoryGirl.create(
          :batch,
          id: batch_id,
          checks: [
            FactoryGirl.create(
              :check,
              link: FactoryGirl.create(:link, uri: uri_a),
            ),
            FactoryGirl.create(
              :check,
              link: FactoryGirl.create(:link, uri: uri_b),
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
          ]
        )
      end

      include_examples "returns batch report", 200
    end
  end

end
