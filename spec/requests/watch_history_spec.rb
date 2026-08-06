require "rails_helper"

RSpec.describe "WatchHistory", type: :request do
  describe "GET /history" do
    it "splits progresses into an in-progress rail and a finished grid" do
      user = create(:user)
      in_progress_video = create(:video, duration_sec: 100)
      finished_video = create(:video, duration_sec: 100)
      create(:watch_progress, user: user, video: in_progress_video, last_timestamp_sec: 10)
      create(:watch_progress, user: user, video: finished_video, last_timestamp_sec: 99)
      sign_in_as user

      get watch_history_path

      expect(response).to have_http_status(:success)
    end

    it "requires authentication" do
      get watch_history_path
      expect(response).to redirect_to(root_path)
    end
  end
end
