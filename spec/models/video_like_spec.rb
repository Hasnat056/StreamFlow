require "rails_helper"

RSpec.describe VideoLike, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:video) }

  it "rejects liking the same video twice" do
    video = create(:video)
    user = create(:user)
    create(:video_like, user: user, video: video)

    duplicate = build(:video_like, user: user, video: video)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("has already liked this video")
  end

  it "allows a self-like on your own video (deliberate)" do
    owner = create(:user)
    video = create(:video, channel: create(:channel, user: owner))

    like = build(:video_like, user: owner, video: video)

    expect(like).to be_valid
  end
end
