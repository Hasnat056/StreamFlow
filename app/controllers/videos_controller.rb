# app/controllers/videos_controller.rb
class VideosController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create ]

  def new
    @channel = Channel.find(params[:channel_id])
    @video = @channel.videos.build
  end

  def create
    @channel = Channel.find(params[:channel_id])
    @video = @channel.videos.build(video_params)

    if @video.save
      # Mark state machine as uploaded if AASM event exists
      @video.mark_as_uploaded! if @video.may_mark_as_uploaded?

      VideoProcessingJob.perform_later(@video.id)

      respond_to do |format|
        # Navigation requirement: Redirect to Video Show page!
        format.html { redirect_to root_path, notice: "Video uploaded! We'll notify you when it's ready to watch" }
        format.json { render json: { status: "ok", video_id: @video.id, url: root_path }, status: :created }
      end
    else
      # Logs exact model validation errors to terminal so we can see why it fails
      Rails.logger.error("Video Save Failed: #{@video.errors.full_messages.join(', ')}")

      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { status: "error", errors: @video.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @channel = Channel.find(params[:channel_id])

    watch_progress_join = current_user ?
      Video.sanitize_sql_array([ "LEFT JOIN watch_progresses ON watch_progresses.video_id = videos.id AND watch_progresses.user_id = ?", current_user.id ]) :
      "LEFT JOIN watch_progresses ON 1 = 0"

    @video = @channel.videos
      .select(<<~SQL.squish)
        videos.*,
        (SELECT COUNT(*) FROM video_views WHERE video_views.video_id = videos.id) AS views_count,
        (SELECT COUNT(*) FROM video_likes WHERE video_likes.video_id = videos.id) AS likes_count,
        video_playlists.master_file_url AS playlist_master_file_url,
        watch_progresses.last_timestamp_sec AS wp_last_timestamp_sec,
        watch_progresses.duration_sec AS wp_duration_sec
      SQL
      .joins("LEFT JOIN video_playlists ON video_playlists.video_id = videos.id AND video_playlists.is_active = true")
      .joins(watch_progress_join)
      .find(params[:id])

    redirect_to root_path, notice: "The video isn't ready to watch yet." and return unless @video.ready?

    @related_videos = @channel.videos.ready.where.not(id: @video.id)
      .select("videos.*, (SELECT COUNT(*) FROM video_views WHERE video_views.video_id = videos.id) AS views_count")
      .order(created_at: :desc)
      .limit(8)
  end

  private

  def video_params
    params.require(:video).permit(:title, :source_file)
  end
end
