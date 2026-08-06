require "rails_helper"

RSpec.describe "VideoLikes", type: :request do
  let(:channel) { create(:channel) }
  let(:video) { create(:video, channel: channel) }

  describe "POST /channels/:channel_id/videos/:video_id/video_like" do
    it "likes the video and replaces the like button via Turbo Stream" do
      sign_in_as create(:user)

      post channel_video_video_like_path(channel, video), as: :turbo_stream

      expect(video.video_likes.count).to eq(1)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end

    it "surfaces the uniqueness error as an alert on the HTML redirect path" do
      user = create(:user)
      create(:video_like, user: user, video: video)
      sign_in_as user

      # The turbo_stream branch only replaces the like button, it doesn't
      # append a toast (unlike SubscriptionsController) — the alert only
      # surfaces via flash on the HTML redirect path.
      post channel_video_video_like_path(channel, video)

      expect(flash[:alert]).to include("has already liked this video")
    end
  end

  describe "DELETE /channels/:channel_id/videos/:video_id/video_like" do
    it "removes the like" do
      user = create(:user)
      create(:video_like, user: user, video: video)
      sign_in_as user

      delete channel_video_video_like_path(channel, video)

      expect(video.video_likes.count).to eq(0)
    end
  end
end
