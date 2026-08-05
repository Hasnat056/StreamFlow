class ChannelAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_owned_channel

  DAYS = 90

  def show
    authorize @channel, :analytics?

    video_ids = @channel.videos.ready.pluck(:id)

    @daily_views = daily_series(VideoView.where(video_id: video_ids))
    @daily_subscribers = daily_subscriber_series
    @video_status_counts = @channel.videos.group(:status).count
    @completion_buckets = completion_buckets(video_ids)

    @video_rows = build_video_rows(video_ids)
    @top_videos = @video_rows.select { |row| row[:video].ready? }.sort_by { |row| -row[:views] }.first(8)

    @total_videos = @channel.videos.count
    @processing_count = @channel.videos.where(status: :processing).count
    @total_likes = VideoLike.where(video_id: video_ids).count
    @total_watch_seconds = @channel.videos.sum(:watch_time)
  end

  private

  def set_owned_channel
    @channel = Channel.find_by!(handle: params[:channel_id])
  end

  def daily_series(scope)
    counts = scope.where(created_at: (DAYS - 1).days.ago.beginning_of_day..).group("DATE(created_at)").count
    (0...DAYS).map do |i|
      date = (DAYS - 1 - i).days.ago.to_date
      { date: date, value: counts[date] || 0 }
    end
  end

  def daily_subscriber_series
    subs = Subscription.where(channel_id: @channel.id)
    cutoff = (DAYS - 1).days.ago.beginning_of_day
    running_total = subs.where("created_at < ?", cutoff).count
    counts = subs.where(created_at: cutoff..).group("DATE(created_at)").count

    (0...DAYS).map do |i|
      date = (DAYS - 1 - i).days.ago.to_date
      running_total += counts[date] || 0
      { date: date, value: running_total }
    end
  end

  def completion_buckets(video_ids)
    buckets = { "0–25%" => 0, "25–50%" => 0, "50–75%" => 0, "75–100%" => 0 }
    WatchProgress.joins(:video).where(video_id: video_ids).pluck(:last_timestamp_sec, "videos.duration_sec").each do |last_sec, duration_sec|
      next unless duration_sec&.positive?

      pct = (last_sec.to_f / duration_sec * 100).clamp(0, 100)
      key = case pct
      when 0...25 then "0–25%"
      when 25...50 then "25–50%"
      when 50...75 then "50–75%"
      else "75–100%"
      end
      buckets[key] += 1
    end
    buckets
  end

  def build_video_rows(video_ids)
    views_by_video = VideoView.where(video_id: video_ids).group(:video_id).count
    likes_by_video = VideoLike.where(video_id: video_ids).group(:video_id).count
    comments_by_video = Comment.where(video_id: video_ids).group(:video_id).count
    avg_watched_by_video = average_watched_by_video(video_ids)

    @channel.videos.order(created_at: :desc).map do |video|
      {
        video: video,
        views: views_by_video[video.id] || 0,
        likes: likes_by_video[video.id] || 0,
        comments: comments_by_video[video.id] || 0,
        avg_watched: avg_watched_by_video[video.id] || 0
      }
    end
  end

  def average_watched_by_video(video_ids)
    rows = WatchProgress.joins(:video).where(video_id: video_ids).pluck(:video_id, :last_timestamp_sec, "videos.duration_sec")
    rows.group_by { |(vid, _, _)| vid }.transform_values do |video_rows|
      percents = video_rows.map { |(_, last_sec, duration_sec)| duration_sec&.positive? ? (last_sec.to_f / duration_sec * 100).clamp(0, 100) : 0 }
      (percents.sum / percents.size).round
    end
  end
end
