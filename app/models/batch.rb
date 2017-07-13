class Batch < ApplicationRecord
  has_many :batch_checks, -> { order(:order) }
  has_many :checks, through: :batch_checks

  def started_at
    checks.minimum(:started_at)
  end

  def completed_at
    checks.maximum(:completed_at) if completed?
  end

  def completed?
    checks.where(completed_at: nil).empty?
  end

  def status
    completed? ? :completed : :in_progress
  end

  def trigger_webhook
    return unless webhook_uri
    return unless completed?
    return if webhook_triggered

    WebhookWorker.perform_async(
      BatchPresenter.new(self).report,
      webhook_uri,
      webhook_secret_token,
      id
    )
  end
end
