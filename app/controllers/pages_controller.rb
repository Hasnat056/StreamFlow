class PagesController < ApplicationController
  def home
    # If a user is logged in, grab their record
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]

    @recent_videos = Video.ready.include(:channel).order(created_at: :desc).limit(24)
  end
end
