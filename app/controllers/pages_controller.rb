class PagesController < ApplicationController
  def home
    @query = params[:q].to_s.strip

    if @query.present?
      # Search bypasses the cache entirely — it's a dynamic, parameterized
      # query the "recent videos" index can't serve.
      @recent_videos = Video.ready.eager_load(:channel).where("title ILIKE ?", "%#{@query}%").order(created_at: :desc).limit(24)
      @views_by_video = VideoView.where(video_id: @recent_videos.map(&:id)).group(:video_id).count
    else
      hydrated = Video.hydrate_cards(Video.recent_ready_ids(limit: 24))
      @recent_videos = hydrated[:videos]
      @views_by_video = hydrated[:views_by_video]
    end

    video_ids = @recent_videos.map(&:id)
    @watch_progress_by_video = current_user ? current_user.watch_progresses.where(video_id: video_ids).select(&:resumable?).index_by(&:video_id) : {}
  end
end
