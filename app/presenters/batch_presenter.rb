class BatchPresenter < SimpleDelegator
  def report
    {
      id:,
      status: status.to_s,
      links: checks.map { |check| CheckPresenter.new(check).link_report },
      totals: {
        links: checks.count,
        ok: checks.each.count { |check| check.status == :ok },
        caution: checks.each.count { |check| check.status == :caution },
        broken: checks.each.count { |check| check.status == :broken },
        pending: checks.each.count { |check| check.status == :pending },
        danger: checks.each.count { |check| check.status == :danger },
      },
      completed_at: completed_at.try(:iso8601),
    }
  end
end
