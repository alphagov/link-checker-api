class Batch < ApplicationRecord
  before_create :set_unique_timestamp_id

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

    WebhookJob.perform_async(
      BatchPresenter.new(self).report.to_json,
      webhook_uri,
      webhook_secret_token,
      id,
    )
  end

private

  def set_unique_timestamp_id
    return if id.present? # Use provided ID if already set, e.g. in tests

    current_epoch = Time.zone.now.to_i

    # Use a transaction to ensure atomicity
    self.id = self.class.transaction do
      # Check if current epoch time is already taken
      if self.class.exists?(id: current_epoch)
        # If taken, get the highest ID and increment
        self.class.maximum(:id).to_i + 1
      else
        current_epoch
      end
    end
  end
end
