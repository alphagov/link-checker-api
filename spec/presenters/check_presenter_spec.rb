require "rails_helper"

RSpec.describe CheckPresenter do
  let(:link) { FactoryGirl.create(:link) }
  let(:check) { FactoryGirl.create(:check, :completed, link: link) }

  subject { described_class.new(check).link_report }

  let(:expected_link_report) do
    {
      checked: check.completed_at.try(:iso8601),
      errors: [],
      problem_summary: nil,
      status: "ok",
      suggested_fix: nil,
      uri: link.uri,
      warnings: []
    }
  end

  it { is_expected.to eq(expected_link_report) }

  context 'when the link has a monitored link but no historical checks yet' do
    let(:check) { FactoryGirl.create(:check, :completed, :with_errors, link: link) }
    let!(:monitor_link) { FactoryGirl.create(:monitor_link, link: link) }

    let(:expected_message) { check.link_errors.first }

    its([:errors]) { is_expected.to include(expected_message) }
  end

  context 'when the link is monitored' do
    let(:monitor_link) { FactoryGirl.create(:monitor_link, link: link) }

    it { is_expected.to eq(expected_link_report) }

    context 'and when the link has a persistent error' do
      let(:check) { FactoryGirl.create(:check, :completed, :with_errors, link: link) }
      let!(:monitor_link) { FactoryGirl.create(:monitor_link, :with_history, link: link) }

      let(:expected_message) { "#{monitor_link.link_errors.first['message']} since #{monitor_link.link_errors.first['started_at']}" }

      its([:errors]) { is_expected.to include(expected_message) }
    end
  end
end
