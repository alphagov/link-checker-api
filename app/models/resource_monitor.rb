class ResourceMonitor < ApplicationRecord
  validates_presence_of :service

  has_many :monitor_links
  has_many :links, through: :monitor_links
end
