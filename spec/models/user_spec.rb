require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:channels) }
  it { is_expected.to have_many(:subscriptions) }
  it { is_expected.to have_many(:video_likes) }
  it { is_expected.to have_many(:comments) }
  it { is_expected.to have_many(:comment_likes) }
  it { is_expected.to have_many(:watch_progresses) }

  describe ".find_or_create_from_omniauth" do
    it "creates a new user from a fresh provider+uid" do
      auth = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "fresh-uid",
        info: { email: "fresh@example.com", name: "Fresh User", image: "http://example.com/a.png" }
      )

      expect { User.find_or_create_from_omniauth(auth) }.to change(User, :count).by(1)

      user = User.find_by(provider: "google_oauth2", uid: "fresh-uid")
      expect(user.email).to eq("fresh@example.com")
      expect(user.username).to eq("Fresh User")
      expect(user.avatar_url).to eq("http://example.com/a.png")
    end

    it "returns the existing user on a repeat login" do
      existing = create(:user, provider: "google_oauth2", uid: "existing-uid")
      auth = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "existing-uid",
        info: { email: "ignored@example.com", name: "Ignored" }
      )

      expect { User.find_or_create_from_omniauth(auth) }.not_to change(User, :count)
      expect(User.find_or_create_from_omniauth(auth)).to eq(existing)
    end

    it "falls back to the email's local part when the OAuth name is blank" do
      auth = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "blank-name-uid",
        info: { email: "localpart@example.com", name: "" }
      )

      user = User.find_or_create_from_omniauth(auth)

      expect(user.username).to eq("localpart")
    end
  end

  describe "#subscribed_to?" do
    it "is true with a real Subscription row" do
      user = create(:user)
      channel = create(:channel)
      create(:subscription, user: user, channel: channel)

      expect(user.subscribed_to?(channel)).to be true
    end

    it "is false without one" do
      expect(create(:user).subscribed_to?(create(:channel))).to be false
    end
  end

  describe "#liked?" do
    it "is true with a real VideoLike row" do
      user = create(:user)
      video = create(:video)
      create(:video_like, user: user, video: video)

      expect(user.liked?(video)).to be true
    end
  end

  describe "#liked_comment?" do
    it "is true with a real CommentLike row" do
      user = create(:user)
      comment = create(:comment)
      create(:comment_like, user: user, comment: comment)

      expect(user.liked_comment?(comment)).to be true
    end
  end
end
