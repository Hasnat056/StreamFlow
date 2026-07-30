class WatchEvent < ApplicationRecord
  belongs_to :video
  belongs_to :user, optional: true

  validates :seconds_watched, numericality: { greater_than: 0 }
end
