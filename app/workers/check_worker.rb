class CheckWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  sidekiq_retries_exhausted do |msg|
    Check.connection_pool.with_connection do |_|
      check = msg["args"].first
      check.update!(
        link_errors: {},
        link_warnings: {
          check_failed: "Could not complete the check."
        },
        completed_at: Time.now
      )
    end
  end

  def perform(check_id)
    check = Check.includes(:link, :batches).find(check_id)

    return trigger_callbacks(check) if check.started_at || check.completed_at

    check.update!(started_at: Time.now)

    report = LinkChecker.new(check.link.uri).call

    check.update!(
      link_errors: report.errors,
      link_warnings: report.warnings,
      completed_at: Time.now
    )

    trigger_callbacks(check)
  end

  def trigger_callbacks(check)
    check.batches.each do |batch|
      WebhookWorker.perform_async(
        BatchPresenter.new(batch).call,
        batch.webhook_uri
      ) if batch.webhook_uri
    end
  end
end
