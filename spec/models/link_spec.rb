require 'rails_helper'

RSpec.describe Link, type: :model do
  describe "validations" do
    it "validates the presence of uri" do
      expect(subject).not_to be_valid
      expect(subject.errors[:uri]).to include("can't be blank")
    end
  end

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
