require "rails_helper"

RSpec.describe CheckPresenter do
  let(:link) { create(:link) }
  let(:check) { create(:check, :completed, link: link) }

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
end
