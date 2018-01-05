desc "Generate a report of all the broken links"
task :report, [:filename] => :environment do |_t, args|
  ReportGeneratorService.new(args[:filename]).call
end
