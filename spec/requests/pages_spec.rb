require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /pages/home" do
    it "succeeds" do
      get pages_home_path

      expect(response).to have_http_status(:success)
    end

    it "searches by title when a query is given, bypassing the cache" do
      matching = create(:video, title: "Ruby on Rails Tutorial")
      non_matching = create(:video, title: "Something else entirely")

      get pages_home_path, params: { q: "rails" }

      expect(response.body).to include(matching.title)
      expect(response.body).not_to include(non_matching.title)
    end

    it "serves from Video.recent_ready_ids/hydrate_cards without a query" do
      video = create(:video)
      video.add_to_home_feed_cache

      get pages_home_path

      expect(response.body).to include(video.title)
    end

    it "includes a resumable progress bar only when signed in" do
      user = create(:user)
      video = create(:video, duration_sec: 100)
      video.add_to_home_feed_cache
      create(:watch_progress, user: user, video: video, last_timestamp_sec: 10)
      sign_in_as user

      get pages_home_path

      expect(response.body).to include("thumb__progress-track")
    end

    it "shows no progress bar for an anonymous visitor" do
      video = create(:video)
      video.add_to_home_feed_cache

      get pages_home_path

      expect(response.body).not_to include("thumb__progress-track")
    end
  end
end
