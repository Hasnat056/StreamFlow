require "rails_helper"

RSpec.describe VideoProcessingJob, type: :job do
  it "calls VideoTranscodingService for the given video id" do
    video = create(:video)
    service = instance_double(VideoTranscodingService, call: true)
    expect(VideoTranscodingService).to receive(:new).with(video).and_return(service)

    VideoProcessingJob.perform_now(video.id)

    expect(service).to have_received(:call)
  end

  it "enqueues on the video_processing queue" do
    expect(VideoProcessingJob.new.queue_name).to eq("video_processing")
  end
end
