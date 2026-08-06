require "rails_helper"

RSpec.describe VideoView, type: :model do
  it { is_expected.to belong_to(:video) }
  it { is_expected.to belong_to(:user).optional }

  it "allows an anonymous view (user optional)" do
    view = build(:video_view, user: nil)
    expect(view).to be_valid
  end

  it "allows multiple views from the same user (not deduped, by design)" do
    video = create(:video)
    user = create(:user)
    create(:video_view, video: video, user: user)

    second = build(:video_view, video: video, user: user)

    expect(second).to be_valid
  end
end
