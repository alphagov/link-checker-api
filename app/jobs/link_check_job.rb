require 'link_check'
require 'uri_checker'

class LinkCheckJob < ActiveJob::Base
  # TODO:
  #   - The Check#ended_at db query param should be stored in the job when
  #     it's persisted.
  #   - Creating the Check record could be more elegant.
  def perform(job)
    job.links.each do |link|
      existing_checks = Check.where(link: link)
                             .where(ended_at.gt(24.hours.ago))

      unless existing_checks && existing_checks.any?
        report = LinkCheck.new(link.uri).call

        Check.create(link_errors: report.errors,
                     link_warnings: report.warnings,
                     ended_at: Time.now)
      end
    end
  end

private

  def ended_at
    Check.arel_table[:ended_at]
  end
end
