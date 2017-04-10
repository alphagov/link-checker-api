class BatchCheck < ApplicationRecord
  belongs_to :batch
  belongs_to :check
end
