class CheckPresenter < SimpleDelegator
  def link_report
    {
      uri: link.uri,
      status: status.to_s,
      checked: completed_at.try(:iso8601),
      errors: link_errors.symbolize_keys,
      warnings: link_warnings.symbolize_keys,
    }
  end
end
