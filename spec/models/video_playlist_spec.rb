require "rails_helper"

RSpec.describe VideoPlaylist, type: :model do
  it "is only returned by Video#active_playlist when is_active is true" do
    video = create(:video)
    create(:video_playlist, video_id: video.id, version: 1, is_active: false)
    active = create(:video_playlist, video_id: video.id, version: 2, is_active: true)

    expect(video.active_playlist).to eq(active)
  end

  it "rejects a duplicate [master_file_url, version] pair at the DB level" do
    playlist = create(:video_playlist)

    expect {
      VideoPlaylist.create!(video_id: create(:video).id, master_file_url: playlist.master_file_url, version: playlist.version)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
