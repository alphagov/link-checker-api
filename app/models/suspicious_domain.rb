class SuspiciousDomain < ApplicationRecord
  validates :domain,
            presence: true,
            uniqueness: true,
            format: {
              with: /\A[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/,
              message: "must be a valid domain without protocol or path",
            }
end
