class Comment < ApplicationRecord
  CACHE_TTL = 120 # backstop only — bust_cache below is the primary invalidation path

  belongs_to :user
  belongs_to :video
  has_many :comment_likes, dependent: :destroy

  validates :comment_text, presence: true
  validates :user_id, uniqueness: { scope: :video_id, message: "has already commented on this video" }

  after_commit :bust_cache

  # Comments + authors + per-comment like counts, cached per video.
  # "liked by me" is deliberately excluded (per-user) — callers merge that
  # in separately from a live, batched CommentLike lookup.
  def self.cached_for_video(video_id)
    Rails.cache.fetch(cache_key_for(video_id), expires_in: CACHE_TTL) do
      where(video_id: video_id)
        .left_joins(:comment_likes)
        .select("comments.*, COUNT(comment_likes.id) AS likes_count")
        .group("comments.id")
        .order(created_at: :desc)
        .includes(:user)
        .to_a
    end
  end

  def self.cache_key_for(video_id)
    "video:#{video_id}:comments"
  end

  def self.bust_cache_for(video_id)
    Rails.cache.delete(cache_key_for(video_id))
  end

  private

  def bust_cache
    self.class.bust_cache_for(video_id)
  end
end
