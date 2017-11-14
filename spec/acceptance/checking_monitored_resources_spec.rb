require "rails_helper"
# rubocop:disable BlockLength
RSpec.describe "Check all links for a monitored resource" do
  let(:resource_monitor) { FactoryGirl.create(:resource_monitor, number_of_links: 1) }

  let(:report) { LinkChecker::UriChecker::Report.new }

  before do
    allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
  end

  subject do
    LinkMonitor::CheckMonitoredLinks.new(resource_monitor: resource_monitor).call
  end
  # rubocop:disable AmbiguousBlockAssociation
  it 'should update last_checked_at for monitor link' do
    expect { subject }.to change { resource_monitor.monitor_links.first.last_checked_at }
  end

  it 'should add another check to a link' do
    expect { subject }.to change { resource_monitor.links.first.checks.count }.by(1)
  end
  # rubocop:enable AmbiguousBlockAssociation

  context 'when another service monitors the same link' do
    let(:other_resource_monitor) do
      LinkMonitor::UpsertResourceMonitor.new(
        links: resource_monitor.links.map(&:uri),
        service: "local-link-manager",
        resource_type: "Test",
        resource_id: 1
      ).call
    end

    before do
      LinkMonitor::CheckMonitoredLinks.new(resource_monitor: other_resource_monitor).call
    end
    # rubocop:disable AmbiguousBlockAssociation
    it 'should update last_checked_at for monitor link' do
      expect { subject }.to change { resource_monitor.monitor_links.first.last_checked_at }
    end

    it 'should not add another check to a link' do
      expect { subject }.not_to change { resource_monitor.links.first.checks.count }
    end
    # rubocop:enable AmbiguousBlockAssociation
  end
end
# rubocop:enable BlockLength
