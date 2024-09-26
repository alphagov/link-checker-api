require "rails_helper"

RSpec.describe CleanupJob do
  describe "perform" do
    let(:link1) { create(:link, id: 1) }
    let(:link2) { create(:link, id: 2) }

    context "with an old check" do
      let(:old_check) { create(:check, link: link1, completed_at: 10.weeks.ago) }
      let(:new_check) { create(:check, link: link2, completed_at: 2.weeks.ago) }
      let!(:old_batch) { create(:batch, checks: [old_check]) }
      let!(:new_batch) { create(:batch, checks: [new_check]) }
      let!(:old_and_new_batch) { create(:batch, checks: [old_check, new_check]) }

      it "removes the check and the associated batches" do
        expect(Check.count).to eq(2)
        expect(Batch.count).to eq(3)

        subject.perform

        expect(Check.count).to eq(1)
        expect(Batch.count).to eq(1)
        expect(Check.first).to eq(new_check)
        expect(Batch.first).to eq(new_batch)

        expect { old_check.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
