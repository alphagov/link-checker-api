class Link < ApplicationRecord
  has_many :checks

  validates_presence_of :uri

  def existing_check
    checks
      .where("ended_at > ?", Time.now - 24.hours)
      .first
  end
end
