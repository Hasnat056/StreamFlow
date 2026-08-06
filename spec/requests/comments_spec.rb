require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:channel) { create(:channel) }
  let(:video) { create(:video, channel: channel) }

  describe "POST /channels/:channel_id/videos/:video_id/comments" do
    it "posts a new comment" do
      sign_in_as create(:user)

      post channel_video_comments_path(channel, video), params: { comment: { comment_text: "Nice!" } }, as: :turbo_stream

      expect(video.comments.count).to eq(1)
      expect(video.comments.first.comment_text).to eq("Nice!")
    end

    it "edits the existing comment instead of erroring on resubmit" do
      sign_in_as create(:user)

      post channel_video_comments_path(channel, video), params: { comment: { comment_text: "First" } }, as: :turbo_stream
      post channel_video_comments_path(channel, video), params: { comment: { comment_text: "Edited" } }, as: :turbo_stream

      expect(video.comments.count).to eq(1)
      expect(video.comments.first.comment_text).to eq("Edited")
    end
  end

  describe "GET /channels/:channel_id/videos/:video_id/comments/:id/edit" do
    it "swaps in the edit form via Turbo Stream for the comment's own author" do
      user = create(:user)
      comment = create(:comment, user: user, video: video)
      sign_in_as user

      get edit_channel_video_comment_path(channel, video, comment), as: :turbo_stream

      expect(response).to have_http_status(:success)
    end

    it "is rejected for a non-author" do
      comment = create(:comment, video: video)
      sign_in_as create(:user)

      # The turbo_stream branch of respond_with_result only replaces the
      # comments list, it doesn't append a toast (unlike SubscriptionsController) —
      # the alert only surfaces via flash on the HTML redirect path.
      get edit_channel_video_comment_path(channel, video, comment)

      expect(flash[:alert]).to eq("You can edit only your own comments")
    end
  end

  describe "GET /channels/:channel_id/videos/:video_id/comments/:id (Cancel)" do
    it "swaps the edit form back out" do
      comment = create(:comment, video: video)
      sign_in_as create(:user)

      get channel_video_comment_path(channel, video, comment), as: :turbo_stream

      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /channels/:channel_id/videos/:video_id/comments/:id" do
    it "removes the comment for the author" do
      user = create(:user)
      comment = create(:comment, user: user, video: video)
      sign_in_as user

      expect { delete channel_video_comment_path(channel, video, comment), as: :turbo_stream }.to change(Comment, :count).by(-1)
    end

    it "is rejected for a non-author, comment persists" do
      comment = create(:comment, video: video)
      sign_in_as create(:user)

      expect { delete channel_video_comment_path(channel, video, comment) }.not_to change(Comment, :count)
      expect(flash[:alert]).to eq("You can only delete your own comments")
    end
  end
end
