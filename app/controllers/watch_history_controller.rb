class WatchHistoryController < ApplicationController
  before_action :authenticate_user!

  def index
    progresses = current_user.watch_progresses.includes(video: :channel).order(updated_at: :desc)
    @in_progress, @finished = progresses.partition(&:resumable?)
    @in_progress = @in_progress.first(12)
    @finished = @finished.first(48)
  end
end
