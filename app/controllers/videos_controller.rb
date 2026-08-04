# app/controllers/videos_controller.rb
class VideosController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create ]

  def new
    @channel = Channel.find(params[:channel_id])
    @video = @channel.videos.build
    @tag_groups = Category.cached_tag_groups
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
        format.html do
          @tag_groups = Category.cached_tag_groups
          render :new, status: :unprocessable_entity
        end
        format.json { render json: { status: "error", errors: @video.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @channel = Channel.find(params[:channel_id])
    @video = Video.cached_attrs(params[:id])
    raise ActiveRecord::RecordNotFound unless @video && @video.channel_id == @channel.id

    redirect_to root_path, notice: "The video isn't ready to watch yet." and return unless @video.ready?

    counts = Video.cached_counts(@video.id)
    @views_count = counts[:views_count]
    @likes_count = counts[:likes_count]

    # Per-user, so never cached — two small indexed lookups.
    @liked_by_me = current_user ? VideoLike.exists?(video_id: @video.id, user_id: current_user.id) : false
    @wp_last_timestamp_sec = current_user ? WatchProgress.where(video_id: @video.id, user_id: current_user.id).pick(:last_timestamp_sec) : nil

    related = Video.related_to(@video, limit: 8)
    @related_videos = related[:videos]
    @related_views_by_video = related[:views_by_video]
  end

  private

  def video_params
    params.require(:video).permit(:title, :source_file, tag_ids: [])
  end
end
