require "rails_helper"

RSpec.describe WatchTimeRollupJob, type: :job do
  it "rolls up pending watch_events into video.watch_time via update_counters" do
    video = create(:video, watch_time: 100)
    create(:watch_event, video: video, seconds_watched: 10)
    create(:watch_event, video: video, seconds_watched: 20)

    WatchTimeRollupJob.perform_now

    expect(video.reload.watch_time).to eq(130)
  end

  it "deletes only events at/below the captured cutoff id, leaving concurrently-inserted rows untouched" do
    video = create(:video, watch_time: 0)
    create(:watch_event, video: video, seconds_watched: 5)

    # The job's SELECT (with MAX(id) AS cutoff_id) fully materializes before
    # Video.update_counters is called for the first row — inserting here
    # lands exactly in that race window, after the snapshot but before the
    # per-video delete.
    concurrent_event = nil
    allow(Video).to receive(:update_counters).and_wrap_original do |method, *args|
      concurrent_event = create(:watch_event, video: video, seconds_watched: 999)
      method.call(*args)
    end

    WatchTimeRollupJob.perform_now

    expect(video.reload.watch_time).to eq(5)
    expect(WatchEvent.exists?(concurrent_event.id)).to be true
  end

  it "groups and sums correctly across multiple videos in one run" do
    video_a = create(:video, watch_time: 0)
    video_b = create(:video, watch_time: 0)
    create(:watch_event, video: video_a, seconds_watched: 10)
    create(:watch_event, video: video_b, seconds_watched: 20)

    WatchTimeRollupJob.perform_now

    expect(video_a.reload.watch_time).to eq(10)
    expect(video_b.reload.watch_time).to eq(20)
  end

  it "no-ops cleanly when there are no pending watch_events" do
    expect { WatchTimeRollupJob.perform_now }.not_to raise_error
  end
end
