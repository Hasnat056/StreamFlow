class WatchProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video

  def create
    progress = @video.watch_progresses.find_or_initialize_by(user: current_user)
    progress.last_timestamp_sec = params[:last_timestamp_sec]
    progress.duration_sec = params[:duration_sec]
    progress.save

    head :no_content
  end

  private

  def set_video
    @video = Channel.find(params[:channel_id]).videos.find(params[:video_id])
  end
end
