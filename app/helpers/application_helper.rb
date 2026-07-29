module ApplicationHelper
  def format_duration(total_seconds)
    minutes, seconds = total_seconds.to_i.divmod(60)
    format("%d:%02d", minutes, seconds)
  end
end
