class WatchProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video

  # Server-side cap on seconds_watched per save: the client only ever reports a
  # small delta (throttled every ~5s of playback), so a value near this ceiling
  # means either a client bug or a forged request, not real watch time.
  MAX_SECONDS_WATCHED_PER_SAVE = 30

  def create
    progress = @video.watch_progresses.find_or_initialize_by(user: current_user)
    progress.last_timestamp_sec = params[:last_timestamp_sec]
    progress.duration_sec = params[:duration_sec]
    progress.save

    seconds_watched = params[:seconds_watched].to_i.clamp(0, MAX_SECONDS_WATCHED_PER_SAVE)
    @video.watch_events.create!(user: current_user, seconds_watched: seconds_watched) if seconds_watched.positive?

    head :no_content
  end

  private

  def set_video
    @video = Channel.find(params[:channel_id]).videos.find(params[:video_id])
  end
end
