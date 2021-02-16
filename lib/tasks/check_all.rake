require "csv"

class ReportLine
  attr_reader :summary, :fix, :errors, :warnings

  def initialize(summary: nil, fix: nil, errors: [], warnings: [])
    @summary = summary
    @fix = fix
    @errors = errors.presence || []
    @warnings = warnings.blank? ? [] : errors
  end

  def is_failing?
    summary.present? || fix.present? || errors.any? || warnings.any?
  end

  def to_s
    output = []
    output << summary if summary.present?
    output << fix if fix.present?
    output << errors.join(" ")
    output << warnings.join(" ")
    output.join(" ")
  end
end

# CSV file structure: url,status,link_errors,link_warnings,problem_summary,suggested_fix
desc "Check a CSV file containing a number of links manually and print the report"
task :check_all, [:filename] => :environment do |_t, args|
  file = File.open("report.txt", "w")
  counts = { urls: 0 }

  CSV.foreach(args.filename, headers: true) do |row|
    if row["url"].present?
      begin
        counts[:urls] += 1

        report = LinkChecker.new(row["url"]).call

        # was = ReportLine.new(
        #         summary: row['problem_summary'],
        #         fix: row['suggested_fix'],
        #         errors: row['link_errors'],
        #         warnings: row['link_warnings'],
        #       )

        now = ReportLine.new(
          summary: report.problem_summary,
          fix: report.suggested_fix,
          errors: report.errors,
          warnings: report.warnings,
        )

        if now.is_failing?
          counts.include?(now.errors) ? counts[now.errors] += 1 : counts[now.errors] = 1
          counts.include?(now.warnings) ? counts[now.warnings] += 1 : counts[now.warnings] = 1
          counts.include?(now.summary) ? counts[now.summary] += 1 : counts[now.summary] = 1

          file.puts row["url"]
          # file.puts "Status [#{row['status'].upcase}]" if row["status"].present?
          # file.puts was if was.to_s.present?
          file.puts now if now.to_s.present?
          file.puts
        end
      rescue StandardError => e
        counts.include?(e.message) ? counts[e.message] += 1 : counts[e.message] = 1
      end
    end
  end

  file.close

  puts counts.inspect
end
