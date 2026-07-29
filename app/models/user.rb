class User < ApplicationRecord
  has_many :channels, dependent: :destroy

  has_many :subscriptions, dependent: :destroy
  has_many :video_likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :comment_likes, dependent: :destroy
  has_many :watch_progresses, dependent: :destroy
  has_many :subscribed_channels, through: :subscriptions, source: :channel


  def subscribed_to?(channel)
    subscriptions.exists?(channel_id: channel.id)
  end

  def liked?(video)
    video_likes.exists?(video_id: video.id)
  end

  def liked_comment?(comment)
    comment_likes.exists?(comment_id: comment.id)
  end

  def self.find_or_create_from_omniauth(auth)
    # 1. Search for existing user
    user = find_by(provider: auth.provider, uid: auth.uid)

    if user
      # User already exists, return them directly
      user
    else
      # Create and set attributes for new user
      new_user = User.new
      new_user.provider   = auth.provider
      new_user.uid        = auth.uid
      new_user.email      = auth.info.email
      new_user.avatar_url = auth.info.image
      new_user.username   = auth.info.name.presence || auth.info.email.split("@").first

      # Save to database and return the user instance
      new_user.save
      new_user
    end
  end
end
