class Link < ApplicationRecord
  has_many :checks

  validates_presence_of :uri

  def find_completed_check(within: 24.hours)
    checks
      .where("ended_at > ?", Time.now - within)
      .first
  end
end
