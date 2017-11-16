require "rails_helper"
# rubocop:disable BlockLength
RSpec.describe "Create an enabled monitor" do
  subject do
    LinkMonitor::UpsertResourceMonitor.new(links: links, app: service, reference: "Text:1").call
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
      LinkMonitor::UpsertResourceMonitor.new(links: links, app: "gov-uk", reference: "Text:2").call
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
    let(:out_of_use_link) { Link.find_by(uri: "http://example.com/a") }

    before do
      resource

      links << "http://example.com/c"
      links.delete("http://example.com/a")
      LinkMonitor::UpsertResourceMonitor.new(links: links, app: resource.app, reference: resource.reference).call
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

    it "should not update any existing links" do
      expect(resource.links.first.id).not_to eq(out_of_use_link.id)
    end
  end

  context "when we supply an organisation" do
    subject do
      LinkMonitor::UpsertResourceMonitor.new(
        links: links,
        app: service,
        reference: "Text:1",
        organisation: "testorg"
      ).call
    end

    its(:organisation) { is_expected.to eq("testorg") }
  end

  context "when we update the organisation" do
    let!(:resource_monitor) { FactoryGirl.create(:resource_monitor, organisation: 'testorg2') }

    subject do
      LinkMonitor::UpsertResourceMonitor.new(
        links: links,
        app: resource_monitor.app,
        reference: resource_monitor.reference,
        organisation: "test_org"
      ).call
    end

    its(:organisation) { is_expected.to eq("test_org") }
  end
end
# rubocop:enable BlockLength
