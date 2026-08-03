class WatchProgress < ApplicationRecord
  RESUMABLE_THRESHOLD = 0.95

  belongs_to :user
  belongs_to :video

  validates :last_timestamp_sec, numericality: { greater_than_or_equal_to: 0 }

  def percent_watched
    return 0 if video.duration_sec.blank?

    ((last_timestamp_sec.to_f / video.duration_sec) * 100).round.clamp(0, 100)
  end

  def resumable?
    return false if video.duration_sec.blank?

    (last_timestamp_sec.to_f / video.duration_sec) < RESUMABLE_THRESHOLD
  end
end
