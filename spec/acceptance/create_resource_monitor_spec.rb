require "rails_helper"
# rubocop:disable BlockLength
RSpec.describe "Create an enabled monitor" do
  subject do
    LinkMonitor::CreateResourceMonitor.new(links: links, service: service).call
  end

  let(:links) { ["http://example.com/a", "http://example.com/b"] }
  let(:service) { "local-link-manager" }

  context "without links" do
    let(:links) { [] }
    it { is_expected.to be_a(ResourceMonitor) }
  end

  context "with links" do
    it { is_expected.to be_a(ResourceMonitor) }

    it "should persist data" do
      monitor = ResourceMonitor.find(subject.id)

      expect(monitor.links).not_to be_empty
      expect(monitor.monitor_links).not_to be_empty
    end
  end

  context "when another monitor exists" do
    before do
      LinkMonitor::CreateResourceMonitor.new(links: links, service: "gov-uk").call
      subject
    end

    it "does not duplicate links" do
      expect(Link.all.count).to eq(2)
    end

    it "does create new monitor links" do
      expect(MonitorLink.all.count).to eq(4)
    end
  end
end
# rubocop:enable BlockLength
