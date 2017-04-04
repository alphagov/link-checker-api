require 'rails_helper'

RSpec.describe Job, type: :model do
  describe "associations" do
    context "for Link" do
      let(:link) { FactoryGirl.build(:link) }

      it "can have many links" do
        subject.links << link
        expect(subject.links).to include(link)
      end
    end
  end
end
