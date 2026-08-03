# frozen_string_literal: true

class Channel < ApplicationRecord
  CATEGORIES = [
    "Gaming",
    "Technology & Science",
    "Education",
    "Entertainment",
    "Music",
    "News & Politics",
    "Sports",
    "Vlogs & Lifestyle",
    "Howto & Style"
  ].freeze
  # Relationships
  belongs_to :user
  has_many :videos, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :subscribers, through: :subscriptions, source: :user

  has_one_attached :avatar
  has_one_attached :banner

  # Keeps channel_avatar_url/channel_banner_url (plain public R2 URLs) in sync
  # with the ActiveStorage attachment, so views can render <img src="..."> directly
  # instead of going through ActiveStorage's redirect controller on every request.
  before_save :sync_avatar_url
  before_save :sync_banner_url

  # Validations
  validates :channel_name, presence: true
  validates :category, presence: true
  validates :user_id, presence: true

  # Ensure user can only have one channel per channel_type (per index constraint)
  validates :channel_type, presence: true,
            uniqueness: { scope: :user_id, message: "already has a channel of this type" }

  # Normalizes comma-separated string inputs for tags into a PostgreSQL array
  def tags_input=(value)
    if value.is_a?(String)
      self.tags = value.split(",").map(&:strip).reject(&:blank?)
    elsif value.is_a?(Array)
      self.tags = value
    end
  end

  # Helper to display tags back as a comma-separated string in forms
  def tags_input
    tags&.join(", ")
  end

  private

  def sync_avatar_url
    self.channel_avatar_url = avatar.attached? ? r2_public_url(avatar.blob.key) : nil
  end

  def sync_banner_url
    self.channel_banner_url = banner.attached? ? r2_public_url(banner.blob.key) : nil
  end

  def r2_public_url(key)
    base_url = Rails.application.credentials.dig(:r2, :public_base_url)
    raise "Missing r2.public_base_url credential - cannot build a channel image URL" if base_url.blank?

    "#{base_url}/#{key}"
  end
end
