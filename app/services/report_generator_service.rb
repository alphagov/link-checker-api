require "csv"

class ReportGeneratorService
  def initialize(filename)
    @filename = filename
  end

  def call
    CSV.open(filename, "w") do |csv|
      csv << csv_headings
      checks_with_errors.each do |check|
        csv << csv_row_for_check(check)
      end
    end
  end

private

  attr_reader :filename

  def checks_with_errors
    Link.includes(:checks)
      .map(&:most_recent_check)
      .compact
      .select do |check|
        check.completed? && check.has_errors?
      end
  end

  def csv_row_for_check(check)
    [check.link.uri, check.completed_at]
  end

  def csv_headings
    %w(uri last_checked)
  end
end
