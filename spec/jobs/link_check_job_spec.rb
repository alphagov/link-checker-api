require 'rails_helper'

RSpec.describe LinkCheckJob do
  describe "perform" do
    let(:link) { FactoryGirl.build(:link, id: 123) }
    let(:job) { FactoryGirl.build(:job, links: [link]) }
    let(:report) { UriChecker::Report.new }
    let(:relation) { double(:relation) }

    before do
      allow_any_instance_of(LinkCheck).to receive(:call).and_return(report)
    end

    context "for previously unchecked links" do
      let(:link_check) { double(:link_check) }

      it "attempts to retrieve existing checks" do
        expect(Check).to receive(:where).with(link: link).and_return(relation)
        expect(relation).to receive(:where).with(an_instance_of(Arel::Nodes::GreaterThan))

        subject.perform(job)
      end

      it "initialises and runs a link check" do
        expect(LinkCheck).to receive(:new)
          .with(link.uri)
          .and_return(link_check)

        expect(link_check).to receive(:call).and_return(report)

        subject.perform(job)
      end

      it "creates a Check record" do
        expect { subject.perform(job) }.to change(Check, :count).by(1)
      end
    end

    context "for previously checked links" do
      before do
        FactoryGirl.create(:check, link: link, ended_at: 1.hour.ago)
      end

      it "finds previous checks within a threshold" do
        expect(Check).to receive(:where).with(link: link).and_return(relation)
        expect(relation).to receive(:where).with(an_instance_of(Arel::Nodes::GreaterThan))

        subject.perform(job)
      end

      it "does not perform a Link Check" do
        expect(LinkCheck).not_to receive(:new)
        expect_any_instance_of(LinkCheck).not_to receive(:call)

        subject.perform(job)
      end
    end
  end
end
