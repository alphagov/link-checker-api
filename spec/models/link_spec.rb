require 'rails_helper'

RSpec.describe Link, type: :model do
  describe "validations" do
    it "validates the presence of uri" do
      expect(subject).not_to be_valid
      expect(subject.errors[:uri]).to include("can't be blank")
    end
  end
  describe "associations" do
    context "for Job" do
      let(:job) { FactoryGirl.build(:job) }

      it "can have many jobs" do
        subject.jobs << job
        expect(subject.jobs).to include(job)
      end
    end
  end
end
