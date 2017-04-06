class CheckJob < ApplicationJob
  queue_as :default

  def perform(check, batch: nil, callback_uri: nil)
    return if check.started_at || check.completed_at

    check.update!(started_at: Time.now)

    report = LinkChecker.new(check.link.uri).call

    check.update!(
      link_errors: report.errors,
      link_warnings: report.warnings,
      completed_at: Time.now
    )

    if callback_uri
      if batch
        WebhookJob.perform_now(batch, callback_uri) if batch.completed?
      else
        WebhookJob.perform_now(check, callback_uri)
      end
    end
  end
end
