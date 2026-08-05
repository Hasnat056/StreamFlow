# frozen_string_literal: true

class VideoProcessingJob < ApplicationJob
  queue_as :video_processing
  def perform(video_id)
    VideoTranscodingService.new(Video.find(video_id)).call
  end
end
