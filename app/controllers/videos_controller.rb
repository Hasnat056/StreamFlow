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
        format.html { redirect_to channel_video_path(@channel, @video), notice: "Video uploaded successfully!" }
        format.json { render json: { status: "ok", video_id: @video.id, url: channel_video_path(@channel, @video) }, status: :created }
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
    @video = @channel.videos.find(params[:id])
  end

  private

  def video_params
    params.require(:video).permit(:title, :source_file)
  end
end
