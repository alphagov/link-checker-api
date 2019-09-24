require "rails_helper"

RSpec.describe Batch, type: :model do
  describe "associations" do
    context "for Check" do
      let(:check) { build(:check) }

      it "can have many checks" do
        subject.checks << check
        expect(subject.checks).to include(check)
      end
    end
  end
end
