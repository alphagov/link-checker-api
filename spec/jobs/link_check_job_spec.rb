require 'rails_helper'

RSpec.describe LinkCheckJob do
  describe "perform" do
    let(:link) { FactoryGirl.build(:link, id: 123) }
    let(:report) { LinkCheck::UriChecker::Report.new }

    before do
      allow_any_instance_of(LinkCheck).to receive(:call).and_return(report)
    end

    context "for previously unchecked links" do
      let(:check) { FactoryGirl.build(:check, link: link) }
      let(:link_check) { double(:link_check) }

      it "initialises and runs a link check" do
        expect(LinkCheck).to receive(:new)
          .with(link.uri)
          .and_return(link_check)

        expect(link_check).to receive(:call).and_return(report)

        subject.perform(check)
      end
    end

    context "for previously checked links" do
      let(:check) { FactoryGirl.build(:check, link: link, started_at: 1.hour.ago) }

      it "does not perform a Link Check" do
        expect(LinkCheck).not_to receive(:new)
        expect_any_instance_of(LinkCheck).not_to receive(:call)

        subject.perform(check)
      end
    end
  end
end
