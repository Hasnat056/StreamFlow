require "rails_helper"

RSpec.describe VideoTag, type: :model do
  it { is_expected.to belong_to(:video) }
  it { is_expected.to belong_to(:tag) }

  it "links a video to a tag" do
    video = create(:video)
    tag = create(:tag)

    video_tag = create(:video_tag, video: video, tag: tag)

    expect(video.reload.tags).to include(tag)
    expect(video_tag.tag).to eq(tag)
  end
end
