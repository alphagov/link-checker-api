require "rails_helper"
# rubocop:disable BlockLength
RSpec.describe "Create an enabled monitor" do
  subject do
    LinkMonitor::UpsertResourceMonitor.new(links: links, service: service, resource_type: "Text", resource_id: 1).call
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
      LinkMonitor::UpsertResourceMonitor.new(links: links, service: "gov-uk", resource_type: "Text", resource_id: 2).call
      subject
    end

    it "does not duplicate links" do
      expect(Link.all.count).to eq(2)
    end

    it "does create new monitor links" do
      expect(MonitorLink.all.count).to eq(4)
    end
  end

  context "when we create another resource monitor for an existing resource monitor" do
    let(:resource) { subject }

    before do
      resource

      links << "http://example.com/c"
      links.delete("http://example.com/a")
      LinkMonitor::UpsertResourceMonitor.new(links: links, service: resource.service, resource_type: resource.resource_type, resource_id: resource.resource_id).call
      resource.reload
    end

    it "should remove link monitoring from links that are no longer used by service" do
      expect(resource.links.map(&:uri)).not_to include("http://example.com/a")
    end

    it "should persist unchanged links" do
      expect(resource.links.map(&:uri)).to include("http://example.com/b")
    end

    it "should create new monitor links for new links" do
      expect(resource.links.map(&:uri)).to include("http://example.com/c")
    end

    it "should only persist 1 resource monitor" do
      expect(ResourceMonitor.count).to eq(1)
    end

    it "should not destroy links" do
      expect(Link.all.count).to eq(3)
    end
  end
end
# rubocop:enable BlockLength
