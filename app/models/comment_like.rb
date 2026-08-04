class CommentLike < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  validates :user_id, uniqueness: { scope: :comment_id, message: "has already liked this comment" }

  after_commit :bust_video_comments_cache

  private

  def bust_video_comments_cache
    # comment can be nil here if this like is being destroyed as part of its
    # comment being destroyed (dependent: :destroy) — Comment's own
    # after_commit already busts the cache in that case.
    Comment.bust_cache_for(comment.video_id) if comment
  end
end
