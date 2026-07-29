class CommentLikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment

  def create
    @comment.comment_likes.find_or_create_by(user: current_user)
    respond_with_result
  end

  def destroy
    @comment.comment_likes.find_by(user: current_user)&.destroy
    respond_with_result
  end

  private

  def set_comment
    @video = Channel.find(params[:channel_id]).videos.find(params[:video_id])
    @comment = @video.comments.find(params[:comment_id])
  end

  def respond_with_result
    respond_to do |format|
      format.html { redirect_to channel_video_path(@video.channel, @video) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("comment_#{@comment.id}",
          partial: "comments/comment", locals: { video: @video, comment: @comment })
      end
    end
  end
end
