class Link < ApplicationRecord
  has_many :checks
  has_many :monitor_links
  has_one :link_history

  validates_presence_of :uri

  def self.fetch_all(uris)
    existing_links = Link.where(uri: uris).all

    new_links = (uris - existing_links.map(&:uri)).map do |uri|
      Link.new(uri: uri)
    end

    import_result = Link.import(new_links)

    existing_links + new_links.select { |link| import_result.ids.include?(link.id) }
  end

  def find_check(within: 4.hours, completed: false)
    scope = checks.created_within(within)
    scope = scope.where.not(completed_at: nil) if completed
    scope.order(:created_at).first
  end
end
