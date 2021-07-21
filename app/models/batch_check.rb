class BatchCheck < ApplicationRecord
  belongs_to :batch, optional: true
  belongs_to :check, optional: true
end
