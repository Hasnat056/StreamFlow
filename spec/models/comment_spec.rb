require "rails_helper"

RSpec.describe Comment, type: :model do
  it { is_expected.to validate_presence_of(:comment_text) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:video) }
  it { is_expected.to have_many(:comment_likes) }

  it "enforces one comment per user per video" do
    video = create(:video)
    user = create(:user)
    create(:comment, user: user, video: video)

    duplicate = build(:comment, user: user, video: video)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("has already commented on this video")
  end

  describe ".cached_for_video" do
    it "includes the author and a per-comment likes_count" do
      video = create(:video)
      comment = create(:comment, video: video)
      create_list(:comment_like, 2, comment: comment)

      cached = Comment.cached_for_video(video.id)

      expect(cached.first.id).to eq(comment.id)
      expect(cached.first.association(:user)).to be_loaded
      expect(cached.first.likes_count.to_i).to eq(2)
    end

    it "is busted when a comment is created" do
      video = create(:video)
      Comment.cached_for_video(video.id)

      create(:comment, video: video)

      expect(Comment.cached_for_video(video.id).size).to eq(1)
    end

    it "is busted when a comment is updated" do
      comment = create(:comment)
      Comment.cached_for_video(comment.video_id)

      comment.update!(comment_text: "Edited!")

      expect(Comment.cached_for_video(comment.video_id).first.comment_text).to eq("Edited!")
    end

    it "is busted when a comment is destroyed" do
      comment = create(:comment)
      Comment.cached_for_video(comment.video_id)

      comment.destroy

      expect(Comment.cached_for_video(comment.video_id)).to be_empty
    end

    it "is busted when a CommentLike is created or destroyed" do
      comment = create(:comment)
      Comment.cached_for_video(comment.video_id)

      like = create(:comment_like, comment: comment)
      expect(Comment.cached_for_video(comment.video_id).first.likes_count.to_i).to eq(1)

      like.destroy
      expect(Comment.cached_for_video(comment.video_id).first.likes_count.to_i).to eq(0)
    end
  end
end
