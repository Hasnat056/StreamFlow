require "rails_helper"

RSpec.describe ChannelTag, type: :model do
  it { is_expected.to belong_to(:channel) }
  it { is_expected.to belong_to(:tag) }

  it "links a channel to a tag" do
    channel = create(:channel)
    tag = create(:tag)

    channel_tag = create(:channel_tag, channel: channel, tag: tag)

    expect(channel.reload.tags).to include(tag)
    expect(channel_tag.tag).to eq(tag)
  end
end
