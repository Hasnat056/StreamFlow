require "rails_helper"

RSpec.describe CommentLike, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:comment) }

  it "rejects liking the same comment twice" do
    comment = create(:comment)
    user = create(:user)
    create(:comment_like, user: user, comment: comment)

    duplicate = build(:comment_like, user: user, comment: comment)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("has already liked this comment")
  end

  it "busts the owning video's comments cache on create" do
    comment = create(:comment)
    Comment.cached_for_video(comment.video_id)

    create(:comment_like, comment: comment)

    expect(Comment.cached_for_video(comment.video_id).first.likes_count.to_i).to eq(1)
  end

  it "busts the owning video's comments cache on destroy" do
    comment = create(:comment)
    like = create(:comment_like, comment: comment)
    Comment.cached_for_video(comment.video_id)

    like.destroy

    expect(Comment.cached_for_video(comment.video_id).first.likes_count.to_i).to eq(0)
  end

  it "does not error when the comment itself is mid-destroy" do
    comment = create(:comment)
    create(:comment_like, comment: comment)

    expect { comment.destroy }.not_to raise_error
  end
end
