require "rails_helper"

RSpec.describe WebhookWorker do
  describe "perform" do
    let(:report) { { some: "json" } }
    let(:webhook_uri) { "http://webhooks-rule.org/webhook" }
    let(:webhook_secret_token) { nil }
    let(:batch) { create(:batch) }
    let(:batch_id) { batch.id }

    context "with a secret key" do
      let(:webhook_secret_token) { "this is a secret key" }

      # http://www.freeformatter.com/hmac-generator.html
      let(:expected_signature) { "d44d805a16b90922edb48f14ff4e858a5d3e39bd" }

      before do
        stub_request(:post, webhook_uri).to_return(status: 200)

        subject.perform(report, webhook_uri, webhook_secret_token, batch_id)
      end

      it "generates a valid signature " do
        expect(a_request(:post, webhook_uri)
          .with(headers: { "X-LinkCheckerApi-Signature": expected_signature }))
          .to have_been_requested
      end

      context "when creating the job multiple times for the same batch" do
        before do
          10.times do
            described_class.perform_async(report, webhook_uri, webhook_secret_token, batch_id)
          end
        end

        it "should only put one job on the queue" do
          expect(WebhookWorker.jobs.size).to eq(1)
        end
      end
    end

    context "with an already triggered batch" do
      before do
        batch.update!(webhook_triggered: true)
      end

      it "doesn't make a request" do
        subject.perform(report, webhook_uri, webhook_secret_token, batch_id)
      end
    end
  end
end
