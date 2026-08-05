class Video < ApplicationRecord
  include AASM
  MAX_TAGS = 8

  COUNTS_TTL = 120 # seconds — views/likes tolerate brief staleness rather than being busted on every view/like
  HOME_FEED_KEY = "home:recent_video_ids"
  HOME_FEED_BOUND = 300 # cached window; scrolling past this falls back to a live query

  belongs_to :channel
  has_many :video_playlists, dependent: :destroy
  has_one :active_playlist, -> { where(is_active: true) }, class_name: "VideoPlaylist"
  has_many :video_views, dependent: :destroy
  has_many :video_likes, dependent: :destroy
  has_many :watch_progresses, dependent: :destroy
  has_many :watch_events, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :video_tags, dependent: :destroy
  has_many :tags, through: :video_tags

  has_one_attached :source_file

  validates :title, presence: true
  validate :tags_within_limit


  enum :status, {
    upload_pending: "upload_pending",
    uploaded: "uploaded",
    processing: "processing",
    ready: "ready",
    failed: "failed"
  }
  # AASM State Machine setup mapped to the 'status' column
  aasm column: :status do
    state :upload_pending, initial: true
    state :uploaded
    state :processing
    state :ready, after_enter: :add_to_home_feed_cache
    state :failed

    # Event 1: File successfully uploaded to R2 directly by client
    event :mark_as_uploaded do
      transitions from: :upload_pending, to: :uploaded
    end

    # Event 2: Sidekiq worker picks up the job and starts FFmpeg
    event :start_processing do
      transitions from: :uploaded, to: :processing
    end

    # Event 3: Transcoding finished, master playlist created
    event :complete_processing do
      transitions from: :processing, to: :ready
    end

    # Event 4: FFmpeg execution or new failed
    event :mark_as_failed do
      transitions from: %i[upload_pending uploaded processing], to: :failed
    end

    after_all_transitions :broadcast_in_process_update
  end

  after_commit :bust_attrs_cache
  after_destroy_commit :purge_remote_storage
  after_destroy_commit :remove_from_home_feed_cache

  def next_hls_version
    (video_playlists.maximum(:version) || 0) + 1
  end

  def hls_output_prefix(version = next_hls_version)
    "videos/#{id}/hls/v#{version}/"
  end

  def thumbnail_key
    "videos/#{id}/thumbnail.jpg"
  end

  # Static-ish video row + active playlist URL + tags. No TTL — correctness
  # comes from bust_attrs_cache firing on every save (title/thumbnail/tags
  # rarely change, so this is cheap), not from staleness tolerance. Tags ride
  # along here (not a separate lookup) since they're just as static as the
  # rest of this data — related_to below relies on them being preloaded.
  def self.cached_attrs(id)
    Rails.cache.fetch("video:#{id}:attrs") do
      includes(:channel, :tags)
        .select("videos.*, video_playlists.master_file_url AS playlist_master_file_url")
        .joins("LEFT JOIN video_playlists ON video_playlists.video_id = videos.id AND video_playlists.is_active = true")
        .find_by(id: id)
    end
  end

  # Views/likes — the volatile part, deliberately split from attrs so a view
  # doesn't force-bust the (much more stable) attrs cache. TTL-only staleness.
  def self.cached_counts(id)
    Rails.cache.fetch("video:#{id}:counts", expires_in: COUNTS_TTL) do
      { views_count: VideoView.where(video_id: id).count, likes_count: VideoLike.where(video_id: id).count }
    end
  end

  # Batch-hydrates a list of video ids into the shape videos/_video_card(_compact)
  # already expect: an array of videos plus views_by_video/likes_by_video
  # lookup hashes — via Redis MGET-style read_multi, not one round trip per id.
  def self.hydrate_cards(ids)
    return { videos: [], views_by_video: {}, likes_by_video: {} } if ids.empty?

    attrs_by_key = Rails.cache.read_multi(*ids.map { |id| "video:#{id}:attrs" })
    counts_by_key = Rails.cache.read_multi(*ids.map { |id| "video:#{id}:counts" })

    videos = []
    views_by_video = {}
    likes_by_video = {}

    ids.each do |id|
      video = attrs_by_key["video:#{id}:attrs"] || cached_attrs(id)
      next unless video

      counts = counts_by_key["video:#{id}:counts"] || cached_counts(id)
      videos << video
      views_by_video[id] = counts[:views_count]
      likes_by_video[id] = counts[:likes_count]
    end

    { videos: videos, views_by_video: views_by_video, likes_by_video: likes_by_video }
  end

  # Cross-channel relatedness via shared tags — live query (GIN/join-indexed,
  # cheap enough not to need its own cache), hydrated from the per-video
  # attrs/counts caches above.
  def self.related_to(video, limit: 8)
    return { videos: [], views_by_video: {}, likes_by_video: {} } if video.tag_ids.empty?

    # Postgres requires ORDER BY columns to appear in the SELECT list under
    # DISTINCT, so created_at has to be plucked alongside id, not just used
    # for ordering.
    ids = joins(:video_tags)
      .where(video_tags: { tag_id: video.tag_ids })
      .where(status: :ready)
      .where.not(id: video.id)
      .distinct
      .order(created_at: :desc)
      .limit(limit)
      .pluck(:id, :created_at)
      .map(&:first)

    hydrate_cards(ids)
  end

  # Most recent ready video ids, newest first — served from a bounded Redis
  # sorted set (score = created_at) so home-feed reads never touch Postgres
  # on the common path. Falls back to a live query only to bootstrap an
  # empty/cold cache (fresh Redis, first deploy).
  def self.recent_ready_ids(limit: 24)
    if REDIS.zcard(HOME_FEED_KEY) > 0
      REDIS.zrevrange(HOME_FEED_KEY, 0, limit - 1).map(&:to_i)
    else
      seed_home_feed_cache.first(limit)
    end
  end

  def self.seed_home_feed_cache
    rows = ready.order(created_at: :desc).limit(HOME_FEED_BOUND).pluck(:id, :created_at)
    return [] if rows.empty?

    REDIS.zadd(HOME_FEED_KEY, rows.map { |id, created_at| [ created_at.to_i, id ] })
    rows.map(&:first)
  end

  private

  def tags_within_limit
    errors.add(:tags, "can have at most #{MAX_TAGS}") if tags.size > MAX_TAGS
  end

  def bust_attrs_cache
    Rails.cache.delete("video:#{id}:attrs")
  end

  # Atomic append + trim — ZADD/ZREMRANGEBYRANK avoid the read-modify-write
  # race a plain cached array would have if two videos finish processing at
  # the same time.
  def add_to_home_feed_cache
    REDIS.zadd(HOME_FEED_KEY, created_at.to_i, id)
    REDIS.zremrangebyrank(HOME_FEED_KEY, 0, -(HOME_FEED_BOUND + 1))
  end

  def remove_from_home_feed_cache
    REDIS.zrem(HOME_FEED_KEY, id)
  end

  # source_file (ActiveStorage) purges itself automatically on destroy; the
  # HLS renditions and thumbnail are uploaded directly to R2 via S3_BUCKET in
  # VideoTranscodingService, outside ActiveStorage, so nothing else deletes
  # them without this.
  def purge_remote_storage
    S3_BUCKET.objects(prefix: "videos/#{id}/").batch_delete!
  end

  # Keeps the owner-only "in-process videos" panel on the channel page live —
  # broadcasts on every AASM transition (upload_pending -> uploaded -> processing
  # -> ready/failed), not just completion, so the status chip updates in place.
  def broadcast_in_process_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{channel.user_id}_notifications",
      target: "in_process_videos",
      partial: "channels/in_process_videos",
      locals: { channel: channel }
    )
  end
end
