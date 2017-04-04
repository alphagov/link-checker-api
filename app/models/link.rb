class Link < ApplicationRecord
  has_and_belongs_to_many :jobs
  validates_presence_of :uri
end
