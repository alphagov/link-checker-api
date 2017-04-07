class BatchPresenter
  def initialize(batch)
    @batch = batch
  end

  def call
    {
      id: batch.id,
      status: batch.status.to_s,
      links: batch.checks.map { |check| CheckPresenter.new(check).call },
      totals: {
        links: batch.checks.count,
        ok: batch.checks.each.count { |check| check.status == :ok },
        caution: batch.checks.each.count { |check| check.status == :caution },
        broken: batch.checks.each.count { |check| check.status == :broken },
        pending: batch.checks.each.count { |check| check.status == :pending },
      },
      completed_at: batch.completed_at.try(:iso8601),
    }.deep_symbolize_keys
  end

private

  attr_reader :batch
end
