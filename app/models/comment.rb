class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :video
  has_many :comment_likes, dependent: :destroy

  validates :comment_text, presence: true
  validates :user_id, uniqueness: { scope: :video_id, message: "has already commented on this video" }
end
