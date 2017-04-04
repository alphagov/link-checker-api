require 'rails_helper'

RSpec.describe Check, type: :model do
  describe "associations" do
    context "for Link" do
      let(:link) { FactoryGirl.build(:link) }
      subject { FactoryGirl.build(:check, link: link) }

      it "belongs_to link" do
        expect(subject.link).to eq(link)
      end
    end
  end
end
