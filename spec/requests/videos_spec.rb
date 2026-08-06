require "rails_helper"

RSpec.describe "Videos", type: :request do
  let(:owner) { create(:user) }
  let(:channel) { create(:channel, user: owner) }

  describe "GET /channels/:channel_id/videos/new" do
    it "requires authentication" do
      get new_channel_video_path(channel)
      expect(response).to redirect_to(root_path)
    end

    it "requires channel ownership" do
      sign_in_as create(:user)
      get new_channel_video_path(channel)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /channels/:channel_id/videos" do
    it "builds the video on the channel, marks it uploaded, and enqueues VideoProcessingJob" do
      sign_in_as owner

      expect {
        post channel_videos_path(channel), params: { video: { title: "My New Video" } }
      }.to change(Video, :count).by(1)

      video = channel.videos.order(:id).last
      expect(video).to be_uploaded
      expect(VideoProcessingJob).to have_been_enqueued.with(video.id)
    end

    it "requires channel ownership" do
      sign_in_as create(:user)

      expect {
        post channel_videos_path(channel), params: { video: { title: "Hijack Attempt" } }
      }.not_to change(Video, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /channels/:channel_id/videos/:id (show)" do
    it "redirects non-ready videos to root with a notice" do
      video = create(:video, :processing, channel: channel)
      get channel_video_path(channel, video)
      expect(response).to redirect_to(root_path)
    end

    it "404s when the video doesn't belong to the given channel" do
      other_channel = create(:channel)
      video = create(:video, channel: other_channel)

      get channel_video_path(channel, video)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /channels/:channel_id/videos/:id (update)" do
    it "changes title/visibility/tags for the owner" do
      video = create(:video, channel: channel)
      sign_in_as owner

      patch channel_video_path(channel, video), params: { video: { title: "Updated Title", visibility: "private" } }

      expect(response).to redirect_to(channel_path(channel))
      video.reload
      expect(video.title).to eq("Updated Title")
      expect(video).to be_hidden
    end

    it "is denied for a non-owner" do
      video = create(:video, channel: channel)
      sign_in_as create(:user)

      patch channel_video_path(channel, video), params: { video: { title: "Hijacked" } }

      expect(response).to redirect_to(root_path)
      expect(video.reload.title).not_to eq("Hijacked")
    end
  end

  describe "DELETE /channels/:channel_id/videos/:id (destroy)" do
    it "removes the video and redirects to the channel for the owner" do
      video = create(:video, channel: channel)
      sign_in_as owner

      expect { delete channel_video_path(channel, video) }.to change(Video, :count).by(-1)
      expect(response).to redirect_to(channel_path(channel))
    end

    it "is denied for a non-owner" do
      video = create(:video, channel: channel)
      sign_in_as create(:user)

      expect { delete channel_video_path(channel, video) }.not_to change(Video, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /channels/:channel_id/videos/:id/toggle_visibility" do
    it "flips visibility and responds with a Turbo Stream replace" do
      video = create(:video, channel: channel)
      sign_in_as owner

      patch toggle_visibility_channel_video_path(channel, video), as: :turbo_stream

      expect(video.reload).to be_hidden
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end
  end
end
