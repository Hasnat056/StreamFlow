class PagesController < ApplicationController
  def home
    # If a user is logged in, grab their record
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]

    # No processing pipeline runs yet, so no video ever reaches status: :ready -
    # an attached source_file is the only real "has a playable file" signal today.
    @recent_videos = Video.joins(:source_file_attachment)
                           .includes(:channel, source_file_attachment: :blob)
                           .order(created_at: :desc)
                           .limit(24)
  end
end
