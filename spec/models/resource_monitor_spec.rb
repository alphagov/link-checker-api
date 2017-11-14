require 'rails_helper'

RSpec.describe ResourceMonitor, type: :model do
  describe "validations" do
    let!(:resource_monitor) do
      FactoryGirl.create(:resource_monitor, resource_type: "Test", resource_id: 1)
    end

    subject do
      ResourceMonitor.create(resource_type: resource_monitor.resource_type, resource_id: resource_monitor.resource_id, service: "govuk")
    end

    it "validates the uniqueness of resource id and type" do
      expect(subject).not_to be_valid
    end
  end
end
