class Video < ApplicationRecord
  include AASM
  belongs_to :channel
  has_many :video_playlists, dependent: :destroy
  has_one :active_playlist, -> {where(is_active: true)}, class_name: "VideoPlaylist"
  has_many :video_views, dependent: :destroy
  has_many :video_likes, dependent: :destroy
  has_many :watch_progresses, dependent: :destroy
  has_many :comments, dependent: :destroy

  has_one_attached :source_file

  validates :title, presence: true


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
    state :ready
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
  end

  # Returns the path prefix in R2 where HLS playlist files and .ts segments will be saved
  def hls_output_prefix
    "videos/#{id}/hls/v1/"
  end

end
