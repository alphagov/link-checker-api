require "rails_helper"

RSpec.describe LinkMonitor::CreateResourceMonitor do
  let(:links) { [] }
  let(:service) { 'govuk' }
  subject { described_class.new(links: links, service: service).call }

  it { is_expected.to be_a(ResourceMonitor) }
end
