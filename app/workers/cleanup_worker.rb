require "sidekiq-scheduler"

class CleanupWorker
  include Sidekiq::Worker

  def perform
    check_ids.each do |check_id|
      CheckWorker.perform_async(check_id)
    end
  end

  def check_ids
    Check.requires_checking.pluck(:id)
  end
end
