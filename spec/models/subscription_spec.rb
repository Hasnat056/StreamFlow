require "rails_helper"

RSpec.describe Subscription, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:channel) }

  it "rejects subscribing twice to the same channel" do
    channel = create(:channel)
    user = create(:user)
    create(:subscription, user: user, channel: channel)

    duplicate = build(:subscription, user: user, channel: channel)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("is already subscribed to this channel")
  end

  it "rejects subscribing to a private channel" do
    subscription = build(:subscription, channel: create(:channel, :hidden))

    expect(subscription).not_to be_valid
    expect(subscription.errors[:channel]).to include("must be public")
  end

  it "rejects subscribing to your own channel" do
    owner = create(:user)
    channel = create(:channel, user: owner)

    subscription = build(:subscription, user: owner, channel: channel)

    expect(subscription).not_to be_valid
    expect(subscription.errors[:base]).to include("can't subscribe to your own channel")
  end
end
