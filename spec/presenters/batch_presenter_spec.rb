require "rails_helper"

RSpec.describe BatchPresenter do
  let(:completed_at) { Time.zone.now }
  let(:checks) do
    [
      create(:check, completed_at:, link: create(:link)),
      create(:check, completed_at:, link: create(:link)),
      create(:check, completed_at:, link: create(:link)),
      create(:check, :with_errors, completed_at:, link: create(:link)),
      create(:check, :with_warnings, completed_at:, link: create(:link)),
      create(:check, :with_danger, completed_at:, link: create(:link)),
    ]
  end
  let(:batch_input) do
    Batch.create(
      id: 123,
      checks:,
    )
  end
  let(:report_output) do
    {
      id: 123,
      status: "completed",
      links: instance_of(Array), # details covered by CheckPresenter spec
      totals: {
        links: 6,
        ok: 3,
        caution: 1,
        broken: 1,
        pending: 0,
        danger: 1,
      },
      completed_at: completed_at.try(:iso8601),
    }
  end

  subject { described_class.new(batch_input).report }

  it { is_expected.to match(hash_including(report_output)) }
end
