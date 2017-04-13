require "rails_helper"

RSpec.describe CheckWorker do
  describe "perform" do
    let(:link) { FactoryGirl.create(:link, id: 123) }
    let(:report) { LinkChecker::UriChecker::Report.new }

    before do
      allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
    end

    context "for previously unchecked links" do
      let(:check) { FactoryGirl.create(:check, link: link) }
      let(:link_checker) { double(:link_checker) }

      it "initialises and runs a link check" do
        expect(LinkChecker).to receive(:new)
          .with(link.uri)
          .and_return(link_checker)

        expect(link_checker).to receive(:call).and_return(report)

        subject.perform(check.id)
      end
    end

    context "for previously checked links" do
      let(:check) { FactoryGirl.create(:check, link: link, created_at: 1.hour.ago, started_at: 1.hour.ago, completed_at: 50.minutes.ago) }

      it "does not perform a Link Check" do
        expect(LinkChecker).not_to receive(:new)
        expect_any_instance_of(LinkChecker).not_to receive(:call)

        subject.perform(check.id)
      end
    end

    context "for links started a long time ago but not yet finished" do
      let(:check) { FactoryGirl.create(:check, link: link, created_at: 1.hour.ago, started_at: 1.hour.ago) }
      let(:link_checker) { double(:link_checker) }

      it "does perform a check" do
        expect(LinkChecker).to receive(:new)
          .with(link.uri)
          .and_return(link_checker)

        expect(link_checker).to receive(:call).and_return(report)

        subject.perform(check.id)
      end
    end

    context "when it is unable to check the link" do
      let(:check) { FactoryGirl.create(:check, link: link, created_at: 1.hour.ago, started_at: 1.hour.ago) }
      let(:msg) { { "args" => [check] } }

      it "sets the check to a warning" do
        described_class.within_sidekiq_retries_exhausted_block(msg) {}
        expect(check.reload.status).to eq(:caution)
      end
    end
  end
end
