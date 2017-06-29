class CheckPresenter < SimpleDelegator
  def link_report
    {
      uri: link.uri,
      status: status.to_s,
      checked: completed_at.try(:iso8601),
      problem_summary: problem_summary,
      errors: link_errors.is_a?(Array) ? link_errors : link_errors.values.flatten,
      warnings: link_warnings.is_a?(Array) ? link_warnings : link_warnings.values.flatten,
      suggested_fix: suggested_fix,
    }
  end
end
