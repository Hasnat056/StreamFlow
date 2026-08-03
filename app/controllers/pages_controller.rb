class PagesController < ApplicationController
  def home
    @query = params[:q].to_s.strip
    videos = Video.ready.eager_load(:channel).order(created_at: :desc)
    videos = videos.where("title ILIKE ?", "%#{@query}%") if @query.present?
    @recent_videos = videos.limit(24)

    video_ids = @recent_videos.map(&:id)
    @watch_progress_by_video = current_user ? current_user.watch_progresses.where(video_id: video_ids).select(&:resumable?).index_by(&:video_id) : {}
    @views_by_video = VideoView.where(video_id: video_ids).group(:video_id).count
  end
end
