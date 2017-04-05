class LinkCheckJob < ApplicationJob
  queue_as :default

  def perform(check)
    return if check.started_at

    check.update!(started_at: Time.now)

    report = LinkCheck.new(link.uri).call

    check.update!(
      link_errors: report.errors,
      link_warnings: report.warnings,
      ended_at: Time.now
    )
  end
end
