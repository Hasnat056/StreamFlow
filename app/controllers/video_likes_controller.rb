# frozen_string_literal: true

class VideoLikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video

  def create
    like = @video.video_likes.new(user: current_user)

    if like.save
      respond_with_result(:notice, "Liked")
    else
      respond_with_result(:alert, like.errors.full_messages.to_sentence)
    end
  end

  def destroy
    @video.video_likes.find_by(user: current_user)&.destroy
    respond_with_result(:notice, "Removed like")
  end

  private
  def set_video
    @video = Channel.find(params[:channel_id]).videos.find(params[:video_id])
  end

  def respond_with_result(kind, message)
    respond_to do |format|
      format.html { redirect_to channel_video_path(@video.channel, @video), kind => message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("like_button_#{@video.id}",
          partial: "shared/like_button", locals: { video: @video })
      end
    end
  end
end
