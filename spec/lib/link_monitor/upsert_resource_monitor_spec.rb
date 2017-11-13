require "rails_helper"

RSpec.describe LinkMonitor::UpsertResourceMonitor do
  let(:links) { [] }
  let(:service) { 'govuk' }
  subject do
    described_class.new(links: links, service: service, resource_type: "Test", resource_id: 1).call
  end

  it { is_expected.to be_a(ResourceMonitor) }
end
