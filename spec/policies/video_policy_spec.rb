require "rails_helper"

RSpec.describe VideoPolicy, type: :policy do
  let(:owner) { create(:user) }
  let(:channel) { create(:channel, user: owner) }
  let(:video) { create(:video, channel: channel) }

  %i[create? update? destroy?].each do |action|
    describe "##{action}" do
      it "is true for the channel owner" do
        expect(VideoPolicy.new(owner, video).public_send(action)).to be true
      end

      it "is false for a non-owner" do
        expect(VideoPolicy.new(create(:user), video).public_send(action)).to be false
      end

      it "is false for an anonymous user" do
        expect(VideoPolicy.new(nil, video).public_send(action)).to be false
      end
    end
  end
end
