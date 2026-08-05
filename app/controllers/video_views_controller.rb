# frozen_string_literal: true

class VideoViewsController < ApplicationController
  before_action :set_video

  def create
    @video.video_views.create!(
      user: current_user,
      session_token: current_user ? nil : anonymous_session_token,
      ip_address: request.remote_ip,
    )
    head :no_content
  end

  private
  def set_video
    @video = Channel.find_by!(handle: params[:channel_id]).videos.find(params[:video_id])
  end

  def anonymous_session_token
    session[:anon_view_token] ||= SecureRandom.uuid
  end
end
