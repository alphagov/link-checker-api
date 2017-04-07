class Batch < ApplicationRecord
  has_and_belongs_to_many :checks

  def started_at
    checks.minimum(:started_at)
  end

  def completed_at
    checks.maximum(:completed_at) if completed?
  end

  def completed?
    checks.where(completed_at: nil).empty?
  end

  def status
    completed? ? :completed : :in_progress
  end
end
