class ResourceMonitor < ApplicationRecord
  validates :app, presence: true
  validates :reference, uniqueness: { scope: :app }, presence: true

  has_many :monitor_links
  has_many :links, through: :monitor_links
end
