require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:channel) { create(:channel) }

  describe "POST /channels/:channel_id/subscription" do
    it "subscribes the current user and responds with a Turbo Stream + toast" do
      user = create(:user)
      sign_in_as user

      post channel_subscription_path(channel), as: :turbo_stream

      expect(channel.subscriptions.exists?(user: user)).to be true
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("Subscribed to #{channel.channel_name}")
    end

    it "requires authentication" do
      post channel_subscription_path(channel)
      expect(response).to redirect_to(root_path)
    end

    it "surfaces the model validation error as an alert toast for a private channel" do
      private_channel = create(:channel, :hidden)
      sign_in_as create(:user)

      post channel_subscription_path(private_channel), as: :turbo_stream

      expect(response.body).to include("must be public")
    end
  end

  describe "DELETE /channels/:channel_id/subscription" do
    it "unsubscribes the current user" do
      user = create(:user)
      create(:subscription, user: user, channel: channel)
      sign_in_as user

      delete channel_subscription_path(channel)

      expect(channel.subscriptions.exists?(user: user)).to be false
    end
  end
end
