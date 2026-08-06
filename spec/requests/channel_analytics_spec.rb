require "rails_helper"

RSpec.describe "ChannelAnalytics", type: :request do
  let(:owner) { create(:user) }
  let(:channel) { create(:channel, user: owner) }

  describe "GET /channels/:channel_id/analytics" do
    it "renders daily views/subscribers series, video rows, and status counts for the owner" do
      create(:video, channel: channel)
      sign_in_as owner

      get channel_analytics_path(channel)

      expect(response).to have_http_status(:success)
    end

    it "is denied for a non-owner" do
      sign_in_as create(:user)

      get channel_analytics_path(channel)

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      get channel_analytics_path(channel)
      expect(response).to redirect_to(root_path)
    end
  end
end
