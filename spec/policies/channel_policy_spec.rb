require "rails_helper"

RSpec.describe ChannelPolicy, type: :policy do
  let(:owner) { create(:user) }
  let(:channel) { create(:channel, user: owner) }

  %i[update? manage? analytics?].each do |action|
    describe "##{action}" do
      it "is true for the owner" do
        expect(ChannelPolicy.new(owner, channel).public_send(action)).to be true
      end

      it "is false for a non-owner" do
        expect(ChannelPolicy.new(create(:user), channel).public_send(action)).to be false
      end

      it "is false for an anonymous user" do
        expect(ChannelPolicy.new(nil, channel).public_send(action)).to be false
      end
    end
  end
end
