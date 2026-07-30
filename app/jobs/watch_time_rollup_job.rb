class WatchTimeRollupJob < ApplicationJob
  queue_as :default

  def perform
    rows = WatchEvent.group(:video_id).select(:video_id, "SUM(seconds_watched) AS total_seconds", "MAX(id) AS cutoff_id")

    rows.each do |row|
      ActiveRecord::Base.transaction do
        Video.update_counters(row.video_id, watch_time: row.total_seconds.to_i)
        WatchEvent.where(video_id: row.video_id, id: ..row.cutoff_id).delete_all
      end
    end
  end
end
