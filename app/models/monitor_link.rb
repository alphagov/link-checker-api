class MonitorLink < ApplicationRecord
  belongs_to :resource_monitor
  belongs_to :link
end
