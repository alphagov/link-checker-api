class Check < ApplicationRecord
  RECHECK_THRESHOLD = 60.minutes

  has_many :batch_checks
  has_many :batches, through: :batch_checks

  belongs_to :link

  scope :created_within, ->(within) { where("created_at > ?", Time.zone.now - within) }
  scope :requires_checking, -> { where(started_at: nil).or(Check.where(completed_at: nil).where("created_at < ?", RECHECK_THRESHOLD.ago)) }

  def self.fetch_all(links, within: 4.hours)
    existing_checks = Check
      .created_within(within)
      .where(link: links)

    new_checks = (links - existing_checks.map(&:link)).map do |link|
      Check.new(link: link)
    end

    import_result = Check.import(new_checks)

    existing_checks + new_checks.select { |check| import_result.ids.include?(check.id) }
  end

  def requires_checking?
    started_at.nil? || (completed_at.nil? && created_at < RECHECK_THRESHOLD.ago)
  end

  def is_pending?
    completed_at.nil?
  end

  def has_errors?
    link_errors.any?
  end

  def has_warnings?
    link_warnings.any?
  end

  def is_ok?
    !is_pending? && !has_errors? && !has_warnings?
  end

  def completed?
    !is_pending?
  end

  def status
    return :pending if is_pending?
    return :broken if has_errors?
    return :caution if has_warnings?

    :ok
  end
end
