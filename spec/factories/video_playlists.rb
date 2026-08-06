FactoryBot.define do
  factory :video_playlist do
    # VideoPlaylist has no `belongs_to :video` declared (see app/models/video_playlist.rb)
    # — only the FK column and Video's own has_many/has_one sides exist — so
    # this can't use FactoryBot's implicit association shorthand.
    video_id { create(:video).id }
    sequence(:master_file_url) { |n| "https://example.com/videos/v#{n}/master.m3u8" }
    version { 1 }
    is_active { true }
  end
end
