class Check < ApplicationRecord
  has_and_belongs_to_many :batches
  belongs_to :link

  scope :created_within, -> (within) { where("created_at > ?", Time.now - within) }

  def self.fetch_all(links, within: 24.hours)
    existing_checks = Check
      .created_within(within)
      .where(link: links)

    existing_checks +
      (links - existing_checks.map(&:link)).map { |link| Check.create!(link: link) }
  end

  def to_h
    {
      uri: link.uri,
      status: status,
      checked: completed_at,
      errors: link_errors,
      warnings: link_warnings,
    }.deep_symbolize_keys
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
    @status ||= determine_status
  end

  after_save { remove_instance_variable(:@status) if defined? @status }

private

  def determine_status
    return :pending if is_pending?
    return :broken if has_errors?
    return :caution if has_warnings?
    :ok
  end
end
