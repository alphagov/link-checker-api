class LinkCheckJob < ApplicationJob
  queue_as :default

  def perform(link)
    check = link.existing_check

    if check.nil? || check.started_at.nil?
      if check.nil?
        check = Check.create!(link: link, started_at: Time.now)
      else
        check.update!(started_at: Time.now)
      end

      report = LinkCheck.new(link.uri).call

      check.update!(
        link_errors: report.errors,
        link_warnings: report.warnings,
        ended_at: Time.now
      )
    end
  end
end
