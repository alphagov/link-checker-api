desc "Check a link manually and print the report"
task :check, [:uri] => :environment do |_t, args|
  report = LinkChecker.new(args.fetch(:uri)).call

  puts "# Summary"
  puts report.problem_summary
  puts

  puts "# Suggested Fix"
  puts report.suggested_fix
  puts

  puts "# Errors"
  report.errors.each { |s| puts(s) }
  puts

  puts "# Warnings"
  report.warnings.each { |s| puts(s) }
end
