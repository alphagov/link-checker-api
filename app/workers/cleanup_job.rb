require "sidekiq-scheduler"

class CleanupJob
  include Sidekiq::Job

  def perform
    checks_to_perform.each do |check_id|
      CheckJob.perform_async(check_id)
    end

    old_batches.delete_all
    old_checks.delete_all
  end

private

  OLD_CHECK_THRESHOLD = 4.weeks

  def checks_to_perform
    Check.requires_checking.pluck(:id)
  end

  def old_checks
    Check.where("completed_at < ?", OLD_CHECK_THRESHOLD.ago)
  end

  def old_batches
    Batch.where(id: BatchCheck.select(:batch_id).where(check: old_checks))
  end
end
