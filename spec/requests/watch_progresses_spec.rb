require "rails_helper"

RSpec.describe "WatchProgresses", type: :request do
  let(:channel) { create(:channel) }
  let(:video) { create(:video, channel: channel, duration_sec: 600) }

  describe "POST /channels/:channel_id/videos/:video_id/watch_progress" do
    it "upserts last_timestamp_sec for the current user+video" do
      user = create(:user)
      sign_in_as user

      post channel_video_watch_progress_path(channel, video), params: { last_timestamp_sec: 42, seconds_watched: 5 }

      expect(response).to have_http_status(:no_content)
      expect(video.watch_progresses.find_by(user: user).last_timestamp_sec).to eq(42)
    end

    it "records a WatchEvent with the clamped seconds_watched" do
      sign_in_as create(:user)

      post channel_video_watch_progress_path(channel, video), params: { last_timestamp_sec: 10, seconds_watched: 500 }

      expect(video.watch_events.last.seconds_watched).to eq(30)
    end

    it "does not record a WatchEvent when seconds_watched is 0" do
      sign_in_as create(:user)

      expect {
        post channel_video_watch_progress_path(channel, video), params: { last_timestamp_sec: 10, seconds_watched: 0 }
      }.not_to change(WatchEvent, :count)
    end

    it "requires authentication" do
      post channel_video_watch_progress_path(channel, video), params: { last_timestamp_sec: 10, seconds_watched: 5 }
      expect(response).to redirect_to(root_path)
    end
  end
end
