class PagesController < ApplicationController
  def home
    @query = params[:q].to_s.strip
    videos = Video.ready.includes(:channel, :video_views).order(created_at: :desc)
    videos = videos.where("title ILIKE ?", "%#{@query}%") if @query.present?
    @recent_videos = videos.limit(24)

    @watch_progress_by_video = current_user ? current_user.watch_progresses.where(video_id: @recent_videos.map(&:id)).select(&:resumable?).index_by(&:video_id) : {}
  end
end
