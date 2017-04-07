class Link < ApplicationRecord
  has_many :checks

  validates_presence_of :uri

  def self.fetch_all(uris)
    existing_links = Link.where(uri: uris).all
    existing_links +
      (uris - existing_links.map(&:uri)).map { |uri| Link.create!(uri: uri) }
  end

  def find_check(within: 24.hours)
    checks.created_within(within).order(:created_at).first
  end
end
