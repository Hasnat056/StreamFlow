# frozen_string_literal: true

class Channel < ApplicationRecord
  MAX_TAGS = 5
  HANDLE_FORMAT = /\A[a-z0-9_]+\z/
  RESERVED_HANDLES = %w[new].freeze
  COUNTS_TTL = 120 # seconds — same staleness tolerance as Video's view/like counts

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
  validates :category_id, presence: true

  validates :handle, presence: true, length: { in: 3..30 },
    format: { with: HANDLE_FORMAT, message: "can only contain lowercase letters, numbers, and underscores" },
    uniqueness: { case_sensitive: false },
    exclusion: { in: RESERVED_HANDLES, message: "is reserved" }

  validate :tags_within_limit
  validate :tags_within_pool

  before_validation :generate_handle, on: :create

  # Handle is system-assigned, never user input, so it can't drift after creation.
  attr_readonly :handle

  # Enum keys are named visible/hidden rather than public/private: Ruby's
  # Module#public/#private (inherited by every class, including this one)
  # would collide with the class-level scopes Rails' enum macro generates
  # for the literal key names, not just the instance ?-methods — same class
  # of bug as the AASM "frozen" state colliding with Object#frozen? earlier.
  # The stored/DB-facing values are still the plain strings "public"/"private".
  enum :visibility, { visible: "public", hidden: "private" }

  after_commit :bust_attrs_cache
  after_commit :sync_videos_on_visibility_change

  # Used everywhere a channel_path/channel_video_path etc. is generated, so
  # URLs are /channels/somehandle instead of /channels/123 without touching
  # any of the call sites.
  def to_param
    handle
  end

  # Static-ish channel row + category + tags, keyed by handle (immutable, so
  # no rename-invalidation to worry about) — same "no TTL, busted on save"
  # reasoning as Video.cached_attrs. skip_nil so a lookup on a bad/removed
  # handle doesn't poison the cache with a permanent miss.
  def self.cached_attrs(handle)
    Rails.cache.fetch("channel:#{handle}:attrs", skip_nil: true) do
      includes(:category, :tags).find_by(handle: handle)
    end
  end

  # Subscriber count — the volatile part, deliberately split from attrs (same
  # split as Video's counts vs attrs). TTL-only staleness, no explicit bust on
  # subscribe/unsubscribe, matching how view/like counts already behave.
  def self.cached_subscriber_count(id)
    Rails.cache.fetch("channel:#{id}:subscriber_count", expires_in: COUNTS_TTL) do
      Subscription.where(channel_id: id).count
    end
  end

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

  def bust_attrs_cache
    Rails.cache.delete("channel:#{handle}:attrs")
  end

  # A channel going public/private doesn't just affect its own page — every
  # ready video's cached attrs (channel preloaded, now stale) and its
  # membership in the home-feed Redis cache both depend on it, not just the
  # video's own visibility (see Video#add_to_home_feed_cache's guard).
  def sync_videos_on_visibility_change
    return unless saved_change_to_visibility?

    videos.ready.find_each do |video|
      Rails.cache.delete("video:#{video.id}:attrs")
      visible? ? video.add_to_home_feed_cache : video.remove_from_home_feed_cache
    end
  end

  # Always system-assigned from the channel name — there's no form field for
  # this, so any incoming value is ignored rather than trusted.
  def generate_handle
    base = channel_name.to_s.downcase.gsub(/[^a-z0-9_]+/, "_").squeeze("_").gsub(/\A_+|_+\z/, "")
    base = "channel" if base.length < 3
    base = base[0, 24].to_s

    candidate = base
    suffix = 1
    while Channel.exists?(handle: candidate)
      candidate = "#{base}_#{suffix}"
      suffix += 1
    end

    self.handle = candidate
  end
end
