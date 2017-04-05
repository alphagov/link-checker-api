class LinkCheckJob < ApplicationJob
  queue_as :default

  # TODO:
  #   - The Check#ended_at db query param should be stored in the job when
  #     it's persisted.
  #   - Creating the Check record could be more elegant.
  def perform(job)
    job.links.each do |link|
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

    job.update!(completed_at: Time.now)
  end
end
