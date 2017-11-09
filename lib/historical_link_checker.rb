class HistoricalLinkChecker
  attr_reader :report

  def initialize(uri, checks)
    @uri = uri
    @checks = sorted_checks(checks)
    @report = LinkChecker::UriChecker::Report.new
  end

  def call
    current_report = LinkChecker.new(uri).call

    if needs_historical_data_check?(current_report)
      check_history(current_report)
    else
      current_report
    end
  end

private

  attr_reader :uri, :checks

  def check_history(current_report)
    if all_checks_have_errors?(checks_since(7.days.ago))
      current_report.add_problem(
        recurred_for_more_than_one_week_error(current_report)
      )
    elsif all_checks_have_errors?(checks_since(4.days.ago))
      current_report.add_problem(
        recurred_for_more_than_three_days_error(current_report)
      )
    else
      current_report
    end
  end

  def needs_historical_data_check?(current_report)
    return false unless current_report.has_errors?
    return false if checks.empty?
    return false unless checks_have_errors?(checks)

    true
  end

  def locale_interpolation_args(current_report)
    { problem: current_report.problem_summary, problem_message: current_report.errors.try(:first) }
  end

  def recurred_for_more_than_one_week_error(current_report)
    HistoricalLinkChecker::Error::RecurredForMoreThanOneWeekLinkError.new(locale_interpolation_args(current_report))
  end

  def recurred_for_more_than_three_days_error(current_report)
    HistoricalLinkChecker::Error::RecurredForMoreThanThreeDaysLinkError.new(locale_interpolation_args(current_report))
  end

  def sorted_checks(checks)
    checks.sort_by { |check| -1 * check.completed_at.to_i }
  end

  def checks_since(date)
    checks.select { |check| check.completed_at > date }
  end

  def checks_have_errors?(checks_to_check)
    checks_to_check.select { |check| check_has_error?(check) }.any?
  end

  def all_checks_have_errors?(checks_to_check)
    checks_to_check.map { |check| check_has_error?(check) }.uniq.size == 1
  end

  def check_has_error?(check)
    check.link_errors.any?
  end
end
