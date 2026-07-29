class WatchProgress < ApplicationRecord
  RESUMABLE_THRESHOLD = 0.95

  belongs_to :user
  belongs_to :video

  validates :last_timestamp_sec, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_sec, numericality: { greater_than: 0 }

  def percent_watched
    ((last_timestamp_sec.to_f / duration_sec) * 100).round.clamp(0, 100)
  end

  def resumable?
    (last_timestamp_sec.to_f / duration_sec) < RESUMABLE_THRESHOLD
  end
end
