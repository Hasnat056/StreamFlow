require "rails_helper"

RSpec.describe "CommentLikes", type: :request do
  let(:channel) { create(:channel) }
  let(:video) { create(:video, channel: channel) }
  let(:comment) { create(:comment, video: video) }

  describe "POST .../comments/:comment_id/comment_like" do
    it "likes a comment and replaces it via Turbo Stream" do
      sign_in_as create(:user)

      post channel_video_comment_comment_like_path(channel, video, comment), as: :turbo_stream

      expect(comment.comment_likes.count).to eq(1)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end
  end

  describe "DELETE .../comments/:comment_id/comment_like" do
    it "removes the like" do
      user = create(:user)
      create(:comment_like, user: user, comment: comment)
      sign_in_as user

      delete channel_video_comment_comment_like_path(channel, video, comment)

      expect(comment.comment_likes.count).to eq(0)
    end
  end
end
