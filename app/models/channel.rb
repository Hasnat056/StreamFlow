# frozen_string_literal: true

class Channel < ApplicationRecord
  MAX_TAGS = 5

  # Relationships
  belongs_to :user
  belongs_to :category
  has_many :videos, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :subscribers, through: :subscriptions, source: :user
  has_many :channel_tags, dependent: :destroy
  has_many :tags, through: :channel_tags

  has_one_attached :avatar
  has_one_attached :banner

  # Keeps channel_avatar_url/channel_banner_url (plain public R2 URLs) in sync
  # with the ActiveStorage attachment, so views can render <img src="..."> directly
  # instead of going through ActiveStorage's redirect controller on every request.
  before_save :sync_avatar_url
  before_save :sync_banner_url

  # Validations
  validates :channel_name, presence: true
  validates :user_id, presence: true

  # Ensure user can only have one channel per channel_type (per index constraint)
  validates :channel_type, presence: true,
            uniqueness: { scope: :user_id, message: "already has a channel of this type" }

  validate :tags_within_limit
  validate :tags_within_pool

  # Tags selectable for this channel: its own category's tags, plus tags
  # under the always-included, non-selectable General category.
  def tag_pool
    general = Category.general
    category_ids = [ category_id, general&.id ].compact
    Tag.joins(:categories).where(categories: { id: category_ids }).distinct
  end

  private

  def tags_within_limit
    errors.add(:tags, "can have at most #{MAX_TAGS}") if tags.size > MAX_TAGS
  end

  def tags_within_pool
    return if category_id.blank?

    invalid_ids = tag_ids - tag_pool.pluck(:id)
    errors.add(:tags, "must belong to the selected category or General") if invalid_ids.any?
  end

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
