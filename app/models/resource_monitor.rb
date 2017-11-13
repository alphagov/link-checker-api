class ResourceMonitor < ApplicationRecord
  validates :service, uniqueness: { scope: %i(resource_type resource_id) },
                      presence: true
  validates_presence_of :resource_type, :resource_id

  has_many :monitor_links
  has_many :links, through: :monitor_links
end
