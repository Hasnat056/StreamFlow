class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :channel

  validates :user_id, uniqueness: { scope: :channel_id, message: "is already subscribed to this channel" }
  validate :channel_must_be_a_creator_channel
  validate :cannot_subscribe_to_own_channel



  private
  def channel_must_be_a_creator_channel
    return if channel.nil?
    errors.add(:channel, "must be a creator channel") unless channel.channel_type == "creator"
  end

  def cannot_subscribe_to_own_channel
    return if channel.nil? || user.nil?
    errors.add(:base, "can't subscribe to your own channel") if channel.user_id == user.id
  end
end
