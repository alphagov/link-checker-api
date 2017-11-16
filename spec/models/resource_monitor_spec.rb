require 'rails_helper'

RSpec.describe ResourceMonitor, type: :model do
  describe "validations" do
    let!(:resource_monitor) do
      FactoryGirl.create(:resource_monitor, reference: "Test:1")
    end

    subject do
      ResourceMonitor.create(reference: resource_monitor.reference, app: "govuk", organisation: "Testorganisation")
    end

    it "validates the uniqueness of resource id and type" do
      expect(subject).not_to be_valid
    end
  end
end
