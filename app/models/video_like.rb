class VideoLike < ApplicationRecord
  belongs_to :user
  belongs_to :video

  validates :user_id, uniqueness: { scope: :video_id, message: "has already liked this video" }
end
