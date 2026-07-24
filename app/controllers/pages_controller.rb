class PagesController < ApplicationController
  def home
    @query = params[:q].to_s.strip
    videos = Video.ready.includes(:channel, :video_views).order(created_at: :desc)
    videos = videos.where("title ILIKE ?", "%#{@query}%") if @query.present?
    @recent_videos = videos.limit(24)
  end
end
