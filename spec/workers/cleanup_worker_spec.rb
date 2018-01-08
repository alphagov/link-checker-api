require "rails_helper"

RSpec.describe CleanupWorker do
  describe "perform" do
    let(:link1) { create(:link, id: 1) }
    let(:link2) { create(:link, id: 2) }

    context "with an old check" do
      let(:check1) { create(:check, link: link1, completed_at: 10.weeks.ago) }
      let(:check2) { create(:check, link: link2, completed_at: 2.weeks.ago) }
      let!(:batch1) { create(:batch, checks: [check1]) }
      let!(:batch2) { create(:batch, checks: [check2]) }
      let!(:batch3) { create(:batch, checks: [check1, check2]) }

      it "removes the check and the associated batches" do
        expect(Check.count).to eq(2)
        expect(Batch.count).to eq(3)

        subject.perform

        expect(Check.count).to eq(1)
        expect(Batch.count).to eq(1)
        expect(Check.first).to eq(check2)
        expect(Batch.first).to eq(batch2)
      end
    end
  end
end
