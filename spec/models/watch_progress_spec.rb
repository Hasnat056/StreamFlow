require "rails_helper"

RSpec.describe WatchProgress, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:video) }
  it { is_expected.to validate_numericality_of(:last_timestamp_sec).is_greater_than_or_equal_to(0) }

  describe "#percent_watched" do
    it "is 0 when the video has no duration_sec" do
      video = create(:video, duration_sec: nil)
      progress = create(:watch_progress, video: video, last_timestamp_sec: 30)

      expect(progress.percent_watched).to eq(0)
    end

    it "is clamped to 0..100" do
      video = create(:video, duration_sec: 100)
      progress = create(:watch_progress, video: video, last_timestamp_sec: 150)

      expect(progress.percent_watched).to eq(100)
    end
  end

  describe "#resumable?" do
    it "is true below the 95% threshold" do
      video = create(:video, duration_sec: 100)
      progress = create(:watch_progress, video: video, last_timestamp_sec: 50)

      expect(progress.resumable?).to be true
    end

    it "is false at or above the threshold" do
      video = create(:video, duration_sec: 100)
      progress = create(:watch_progress, video: video, last_timestamp_sec: 96)

      expect(progress.resumable?).to be false
    end

    it "is false when the video has no duration_sec" do
      video = create(:video, duration_sec: nil)
      progress = create(:watch_progress, video: video, last_timestamp_sec: 30)

      expect(progress.resumable?).to be false
    end
  end
end
