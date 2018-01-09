require 'rails_helper'

RSpec.describe LinkHistory, type: :model do
  describe "#update_errors" do
    let(:link_history) { create(:link_history, :with_link) }
    let(:errors) do
      ["an error"]
    end

    before do
      link_history.update_errors(errors)
    end

    it "does not add the same error twice" do
      link_history.update_errors(errors)
      expect(link_history.link_errors.count).to eq(1)
    end
  end
end
