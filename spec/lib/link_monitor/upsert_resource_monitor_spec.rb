require "rails_helper"

RSpec.describe LinkMonitor::UpsertResourceMonitor do
  let(:links) { [] }

  subject do
    described_class.new(links: links, app: 'govuk', reference: "test:1").call
  end

  it { is_expected.to be_a(ResourceMonitor) }
end
