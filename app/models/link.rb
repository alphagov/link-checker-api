class Link < ApplicationRecord
  has_and_belongs_to_many :jobs
  has_many :checks

  validates_presence_of :uri

  def existing_check
    checks
      .where(ended_at.gt(24.hours.ago))
      .first
  end

private

  def ended_at
    Check.arel_table[:ended_at]
  end
end
