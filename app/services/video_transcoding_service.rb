
# frozen_string_literal: true

class VideoTranscodingService
  RENDITION_LADDER = [
    { height: 1080, video_bitrate: "5000k", audio_bitrate: "192k" },
    { height: 720,  video_bitrate: "2800k", audio_bitrate: "128k" },
    { height: 480,  video_bitrate: "1400k", audio_bitrate: "128k" }
  ].freeze

  # Every object written here lives under a versioned key (hls/vN/, or the
  # thumbnail overwritten only as part of the same reprocess) - per SRS 7.3,
  # finished VOD output never changes in place, so it's safe for the CDN and
  # browsers to cache it forever.
  IMMUTABLE_CACHE_CONTROL = "public, max-age=31536000, immutable"

  def initialize(video)
    @video = video
  end

  def call
    return unless @video.may_start_processing?
    @video.start_processing!

    version = @video.next_hls_version
    prefix = @video.hls_output_prefix(version)

    source_url = @video.source_file.blob.url(expires_in: 6.hours, disposition: :inline)
    movie = FFMPEG::Movie.new(source_url)
    renditions = renditions_for(movie.height)

    Dir.mktmpdir do |tmp_dir|
      variant_infos = renditions.map { |rendition| transcode_rendition(movie, rendition, tmp_dir) }
      write_master_playlist(tmp_dir, variant_infos)
      upload_directory(tmp_dir, prefix)
      thumbnail_url = generate_and_upload_thumbnail(movie, tmp_dir)

      master_url = master_playlist_url(prefix)
      activate_new_playlist(master_url, version)
      attrs = { duration_sec: movie.duration.round }
      attrs[:thumbnail_url] = thumbnail_url if thumbnail_url
      @video.update!(attrs)
      @video.complete_processing!
      broadcast_ready_notification
    end

  rescue => e
    handle_failure(e)
  end


  private
  def renditions_for(source_height)
    candidates = RENDITION_LADDER.select { |r| r[:height] <= source_height }
    candidates.presence || [ RENDITION_LADDER.min_by { |r| r[:height] }.merge(height: source_height) ]
  end

  def transcode_rendition(movie, rendition, tmp_dir)
    dir = File.join(tmp_dir, "#{rendition[:height]}p")
    FileUtils.mkdir_p(dir)
    output = File.join(dir, "playlist.m3u8")

    args = [
      "-vf", "scale=-2:#{rendition[:height]}",
      "-c:v", "h264", "-b:v", rendition[:video_bitrate],
      "-c:a", "aac", "-b:a", rendition[:audio_bitrate],
      "-hls_time", "6", "-hls_playlist_type", "vod",
      "-hls_segment_filename", File.join(dir, "segment_%03d.ts"),
      "-f", "hls"
    ]

    movie.transcode(output, args)
    width = (rendition[:height] * movie.width / movie.height.to_f).round
    {
      label: "#{rendition[:height]}p",
      bandwidth: bitrate_to_bps(rendition[:video_bitrate], rendition[:audio_bitrate]),
      width: width,
      height: rendition[:height]
    }
  end
  def handle_failure(error)
    Rails.logger.error("VideoTranscodingService failed for video #{@video.id}: #{error.message}")
    @video.update!(processing_error: error.message) if @video.persisted?
    @video.mark_as_failed! if @video.may_mark_as_failed?
  end

  def write_master_playlist(tmp_dir, variant_infos)
    lines = [ "#EXTM3U", "#EXT-X-VERSION:3" ]
    variant_infos.each do |variant|
      lines << "#EXT-X-STREAM-INF:BANDWIDTH=#{variant[:bandwidth]},RESOLUTION=#{variant[:width]}x#{variant[:height]}"
      lines << "#{variant[:label]}/playlist.m3u8"
    end
    File.write(File.join(tmp_dir, "master.m3u8"), lines.join("\n") + "\n")
  end

  def upload_directory(tmp_dir, prefix)
    Dir.glob(File.join(tmp_dir, "**", "*")).each do |path|
      next if File.directory?(path)
      relative_key = path.delete_prefix("#{tmp_dir}/")
      key = "#{prefix}#{relative_key}"
      S3_BUCKET.object(key).upload_file(
        path,
        content_type: content_type_for(path),
        cache_control: IMMUTABLE_CACHE_CONTROL
      )
    end
  end

  def content_type_for(path)
    case File.extname(path)
    when ".m3u8" then "application/vnd.apple.mpegurl"
    when ".ts" then "video/mp2t"
    else "application/octet-stream"
    end
  end

  def master_playlist_url(prefix)
    "#{r2_public_base_url}/#{prefix}master.m3u8"
  end

  def generate_and_upload_thumbnail(movie, tmp_dir)
    output = File.join(tmp_dir, "thumbnail.jpg")
    movie.screenshot(output, seek_time: thumbnail_seek_time(movie), resolution: "640x360")
    return nil unless File.exist?(output)

    key = @video.thumbnail_key
    S3_BUCKET.object(key).upload_file(
      output,
      content_type: "image/jpeg",
      cache_control: IMMUTABLE_CACHE_CONTROL,
    )
    "#{r2_public_base_url}/#{key}"
  end

  def thumbnail_seek_time(movie)
    duration = movie.duration.to_f
    duration <= 0 ? 0 : [ duration * 0.1, 3 ].min
  end

  def r2_public_base_url
    base_url = Rails.application.credentials.dig(:r2, :public_base_url)
    raise "Missing r2.public_base_url credential - cannot build a playable master playlist URL" if base_url.blank?

    base_url
  end

  def activate_new_playlist(master_url, version)
    @video.video_playlists.update_all(is_active: false)
    @video.video_playlists.create!(master_file_url: master_url, version: version, is_active: true)
  end

  def bitrate_to_bps(*bitrates)
    bitrates.sum { |bitrate| bitrate.to_s.delete_suffix("k").to_i * 1000 }
  end

  def broadcast_ready_notification
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{@video.channel.user_id}_notifications",
      target: "notifications",
      partial: "shared/toast",
      locals: {
        kind: :notice,
        message: "\"#{@video.title}\" is ready",
        link: Rails.application.routes.url_helpers.channel_video_path(@video.channel, @video),
        link_text: "▶ Watch now",
        persistent: true
      }
    )
  end
end
