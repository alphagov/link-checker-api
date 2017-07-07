require "sidekiq-scheduler"

class CleanupWorker
  include Sidekiq::Worker

  def perform
    checks_to_perform.each do |check_id|
      CheckWorker.perform_async(check_id)
    end

    old_batches.delete_all
    old_checks.delete_all
  end

private

  OLD_CHECK_THRESHOLD = 4.weeks.ago

  def checks_to_perform
    Check.requires_checking.pluck(:id)
  end

  def old_checks
    Check.where("completed_at < ?", OLD_CHECK_THRESHOLD)
  end

  def old_batches
    Batch.where(id: [BatchCheck.where(check: [old_checks]).pluck(:batch_id)])
  end
end
