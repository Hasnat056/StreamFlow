module ApplicationHelper
  def format_duration(total_seconds)
    minutes, seconds = total_seconds.to_i.divmod(60)
    format("%d:%02d", minutes, seconds)
  end

  def status_chip_class(status)
    case status.to_s
    when "processing" then "status-chip--processing"
    when "failed" then "status-chip--failed"
    when "ready" then "status-chip--ready"
    else "status-chip--pending"
    end
  end

  def status_color(status)
    case status.to_s
    when "processing" then "var(--warning-text)"
    when "failed" then "var(--danger-text)"
    when "ready" then "var(--success-text)"
    else "var(--faint)"
    end
  end

  def format_watch_time(total_seconds)
    hours = total_seconds.to_i / 3600
    minutes = (total_seconds.to_i % 3600) / 60
    "#{hours}h #{minutes}m"
  end
end
