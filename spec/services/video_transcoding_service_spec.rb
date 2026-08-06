require "rails_helper"

RSpec.describe VideoTranscodingService, type: :service do
  let(:channel) { create(:channel) }
  let(:video) { create(:video, :upload_pending, channel: channel) }
  let(:fake_movie) { instance_double(FFMPEG::Movie, height: 1080, width: 1920, duration: 125.4) }
  let(:fake_s3_object) { instance_double(Aws::S3::Object, upload_file: true) }

  before do
    # ActiveStorage's Disk service needs url_options to build a blob URL;
    # normally supplied by the current request, which doesn't exist here.
    ActiveStorage::Current.url_options = { host: "example.com" }

    video.mark_as_uploaded!
    video.source_file.attach(io: StringIO.new("fake video bytes"), filename: "source.mp4", content_type: "video/mp4")

    allow(FFMPEG::Movie).to receive(:new).and_return(fake_movie)
    allow(fake_movie).to receive(:transcode) { |output, *_| File.write(output, "fake-hls") }
    allow(fake_movie).to receive(:screenshot) { |output, *_| File.write(output, "fake-jpeg") }
    allow(S3_BUCKET).to receive(:object).and_return(fake_s3_object)
  end

  def perform
    described_class.new(video).call
  end

  it "transitions uploaded -> processing -> ready on success" do
    perform
    expect(video.reload).to be_ready
  end

  it "is a no-op when the video may not start_processing" do
    video.start_processing!

    expect { perform }.not_to change { video.reload.status }
  end

  it "selects a rendition ladder capped at the source height" do
    allow(fake_movie).to receive(:height).and_return(720)

    expect(fake_movie).to receive(:transcode).twice # 720p and 480p rungs both <= 720

    perform
  end

  it "falls back to a single rendition matching source height when smaller than the smallest ladder rung" do
    allow(fake_movie).to receive(:height).and_return(240)

    expect(fake_movie).to receive(:transcode).once

    perform
  end

  it "writes a master playlist referencing every rendition" do
    uploaded_keys = []
    allow(S3_BUCKET).to receive(:object) { |key| uploaded_keys << key; fake_s3_object }

    perform

    expect(uploaded_keys).to include("videos/#{video.id}/hls/v1/master.m3u8")
  end

  it "uploads every generated file under the versioned hls_output_prefix, plus the thumbnail separately" do
    uploaded_keys = []
    allow(S3_BUCKET).to receive(:object) { |key| uploaded_keys << key; fake_s3_object }

    perform

    hls_prefix = "videos/#{video.id}/hls/v1/"
    hls_keys = uploaded_keys - [ "videos/#{video.id}/thumbnail.jpg" ]
    expect(hls_keys).not_to be_empty
    expect(hls_keys).to all(start_with(hls_prefix))
    expect(uploaded_keys).to include("videos/#{video.id}/thumbnail.jpg")
  end

  it "activates the new playlist and deactivates prior ones" do
    old_playlist = video.video_playlists.create!(master_file_url: "https://example.com/old/master.m3u8", version: 1, is_active: true)

    perform

    expect(old_playlist.reload.is_active).to be false
    expect(video.video_playlists.order(:id).last.is_active).to be true
  end

  it "sets duration_sec and thumbnail_url on success" do
    perform

    video.reload
    expect(video.duration_sec).to eq(125)
    expect(video.thumbnail_url).to be_present
  end

  it "broadcasts a ready Turbo Stream notification" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_append_to)
      .with("user_#{channel.user_id}_notifications", hash_including(target: "notifications"))

    perform
  end

  describe "failure handling" do
    it "catches a raised error, records processing_error, and transitions to failed" do
      allow(fake_movie).to receive(:transcode).and_raise(StandardError, "ffmpeg blew up")

      perform

      video.reload
      expect(video).to be_failed
      expect(video.processing_error).to eq("ffmpeg blew up")
    end

    it "does not blow up the failure handler when the video isn't persisted at the moment of failure" do
      # persisted? is checked because @video.update! would behave unpredictably
      # on a still-new record — mark_as_failed! itself (called unconditionally
      # right after) is what actually ends up persisting it, via AASM's own
      # save step, so this only verifies no exception escapes handle_failure,
      # not that the record stays unsaved afterward.
      unpersisted_video = build(:video, :upload_pending, channel: channel)
      allow(unpersisted_video).to receive(:may_start_processing?).and_return(true)
      allow(unpersisted_video).to receive(:start_processing!).and_raise(StandardError, "boom before persistence")

      expect { described_class.new(unpersisted_video).call }.not_to raise_error
    end
  end
end
