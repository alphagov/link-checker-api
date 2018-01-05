require "rails_helper"

RSpec.describe ReportGeneratorService do
  context "with some broken links" do
    before do
      # completed broken links
      5.times do |i|
        link = FactoryGirl.create(:link, uri: "https://www.example.org/#{i}")
        FactoryGirl.create(:check, :completed, :with_errors, link: link)
      end

      # uncompleted broken link
      FactoryGirl.create(:check, :with_errors, link: FactoryGirl.create(:link, uri: "https://www.example.org/checking"))

      # completed ok link
      FactoryGirl.create(:check, :completed, link: FactoryGirl.create(:link))
    end

    it "creates a CSV file" do
      Tempfile.create("report.csv") do |file|
        described_class.new(file.path).call

        expect(file.readlines.length).to eq(1 + 5)
      end
    end
  end
end
