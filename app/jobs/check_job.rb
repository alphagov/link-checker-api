class CheckJob < ApplicationJob
  queue_as :default

  def perform(check)
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
      WebhookJob.perform_now(
        BatchPresenter.new(batch).call,
        batch.webhook_uri
      ) if batch.webhook_uri
    end
  end
end
