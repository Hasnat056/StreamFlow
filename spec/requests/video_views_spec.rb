require "rails_helper"

RSpec.describe "VideoViews", type: :request do
  let(:channel) { create(:channel) }
  let(:video) { create(:video, channel: channel) }

  describe "POST /channels/:channel_id/videos/:video_id/video_view" do
    it "records a view for a signed-in user" do
      sign_in_as create(:user)

      post channel_video_video_view_path(channel, video)

      expect(response).to have_http_status(:no_content)
      expect(video.video_views.count).to eq(1)
      expect(video.video_views.first.user_id).not_to be_nil
    end

    it "records an anonymous view keyed by session[:anon_view_token]" do
      post channel_video_video_view_path(channel, video)

      expect(video.video_views.first.user_id).to be_nil
      expect(video.video_views.first.session_token).to be_present
    end

    it "does not dedupe repeated views" do
      post channel_video_video_view_path(channel, video)
      post channel_video_video_view_path(channel, video)

      expect(video.video_views.count).to eq(2)
    end
  end
end
