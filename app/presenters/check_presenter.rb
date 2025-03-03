class CheckPresenter < SimpleDelegator
  def link_report
    {
      uri: link.uri,
      status: status.to_s,
      checked: completed_at.try(:iso8601),
      problem_summary:,
      errors: link_errors,
      warnings: link_warnings,
      danger: link_danger,
      suggested_fix:,
    }
  end
end
