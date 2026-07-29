# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video

  def show
    @comment = @video.comments.find(params[:id])

    respond_to do |format|
      format.html { redirect_to channel_video_path(@video.channel, @video) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "comments/comment", locals: { video: @video, comment: @comment })
      end
    end
  end

  def create
    @comment = @video.comments.find_or_initialize_by(user: current_user)
    @comment.comment_text = comment_params[:comment_text]

    if @comment.save
      respond_with_result(:notice, "Comment posted")
    else
      respond_with_result(:alert, @comment.errors.full_messages.to_sentence)
    end
  end

  def destroy
    comment = @video.comments.find(params[:id])
    if comment.user_id == current_user.id
      comment.destroy
      respond_with_result(:notice, "Comment deleted")
    else
      respond_with_result(:alert, "You can only delete your own comments")
    end
  end

  def edit
    @comment = @video.comments.find(params[:id])
    if @comment.user_id == current_user.id
      respond_to do |format|
        format.html { redirect_to channel_video_path(@video.channel, @video) }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "comments/edit_form", locals: { video: @video, comment: @comment })
        end
      end
    else
      respond_with_result(:alert, "You can edit only your own comments")
    end
  end

  private
  def set_video
    @video = Channel.find(params[:channel_id]).videos.find(params[:video_id])
  end

  def comment_params
    params.require(:comment).permit(:comment_text)
  end

  def respond_with_result(kind, message)
    respond_to do |format|
      format.html { redirect_to channel_video_path(@video.channel, @video), kind => message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("comments_list", partial: "comments/list", locals: { video: @video })
      end
    end
  end
end
