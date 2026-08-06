require "rails_helper"

RSpec.describe Video, type: :model do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to belong_to(:channel) }
  it { is_expected.to have_many(:video_playlists) }
  it { is_expected.to have_many(:video_views) }
  it { is_expected.to have_many(:video_likes) }
  it { is_expected.to have_many(:comments) }

  describe "tags_within_limit" do
    it "rejects more than MAX_TAGS tags" do
      video = create(:video)
      extra_tags = Array.new(Video::MAX_TAGS + 1) { create(:tag) }

      video.tags = extra_tags

      expect(video).not_to be_valid
      expect(video.errors[:tags]).to include("can have at most #{Video::MAX_TAGS}")
    end
  end

  describe "visibility" do
    it "defaults to public" do
      expect(build(:video)).to be_visible
    end
  end

  describe ".discoverable" do
    it "includes a ready+public video on a public channel" do
      video = create(:video)
      expect(Video.discoverable).to include(video)
    end

    it "excludes a private video" do
      video = create(:video, :hidden)
      expect(Video.discoverable).not_to include(video)
    end

    it "excludes a public video on a private channel" do
      video = create(:video, channel: create(:channel, :hidden))
      expect(Video.discoverable).not_to include(video)
    end

    it "excludes a non-ready video" do
      video = create(:video, :processing)
      expect(Video.discoverable).not_to include(video)
    end
  end

  describe "AASM lifecycle" do
    it "mark_as_uploaded! transitions upload_pending to uploaded" do
      video = create(:video, :upload_pending)
      video.mark_as_uploaded!
      expect(video).to be_uploaded
    end

    it "start_processing! transitions uploaded to processing" do
      video = create(:video, :upload_pending)
      video.mark_as_uploaded!

      video.start_processing!

      expect(video).to be_processing
    end

    it "complete_processing! transitions processing to ready and adds it to the home feed cache" do
      video = create(:video, :upload_pending)
      video.mark_as_uploaded!
      video.start_processing!

      video.complete_processing!

      expect(video).to be_ready
      expect(REDIS.zrange(Video::HOME_FEED_KEY, 0, -1)).to include(video.id.to_s)
    end

    it "mark_as_failed! transitions upload_pending, uploaded, or processing to failed" do
      fresh = create(:video, :upload_pending)
      fresh.mark_as_failed!
      expect(fresh).to be_failed

      mid_pipeline = create(:video, :upload_pending)
      mid_pipeline.mark_as_uploaded!
      mid_pipeline.start_processing!
      mid_pipeline.mark_as_failed!
      expect(mid_pipeline).to be_failed
    end

    it "rejects an invalid transition" do
      video = create(:video)
      expect(video.may_start_processing?).to be false
      expect { video.start_processing! }.to raise_error(AASM::InvalidTransition)
    end
  end

  describe "home feed cache" do
    it "add_to_home_feed_cache is a no-op when the video is private" do
      video = create(:video, :hidden)
      video.add_to_home_feed_cache
      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)
    end

    it "add_to_home_feed_cache is a no-op when the channel is private" do
      video = create(:video, channel: create(:channel, :hidden))
      video.add_to_home_feed_cache
      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)
    end

    it "remove_from_home_feed_cache removes the video id from the sorted set" do
      video = create(:video)
      video.add_to_home_feed_cache
      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(1)

      video.remove_from_home_feed_cache

      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)
    end
  end

  describe "caching" do
    it "cached_attrs preloads channel and tags" do
      video = create(:video)

      cached = Video.cached_attrs(video.id)

      expect(cached.id).to eq(video.id)
      expect(cached.association(:channel)).to be_loaded
      expect(cached.association(:tags)).to be_loaded
    end

    it "cached_attrs is busted when the video is saved" do
      video = create(:video)
      Video.cached_attrs(video.id)

      video.update!(title: "Freshly Renamed Video")

      expect(Video.cached_attrs(video.id).title).to eq("Freshly Renamed Video")
    end

    it "cached_counts reflects real views and likes counts" do
      video = create(:video)
      create(:video_view, video: video)
      create(:video_like, video: video)

      counts = Video.cached_counts(video.id)

      expect(counts[:views_count]).to eq(1)
      expect(counts[:likes_count]).to eq(1)
    end

    it "hydrate_cards returns videos, views_by_video, and likes_by_video in the given id order" do
      first = create(:video)
      second = create(:video)

      hydrated = Video.hydrate_cards([ first.id, second.id ])

      expect(hydrated[:videos].map(&:id)).to eq([ first.id, second.id ])
      expect(hydrated[:views_by_video]).to have_key(first.id)
    end
  end

  describe "#sync_home_feed_cache_on_visibility_change" do
    it "removes an already-ready video from the feed when it goes private" do
      video = create(:video)
      video.add_to_home_feed_cache

      video.update!(visibility: "private")

      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)
    end

    it "adds an already-ready video to the feed when it goes public again" do
      video = create(:video, :hidden)

      video.update!(visibility: "public")

      expect(REDIS.zrange(Video::HOME_FEED_KEY, 0, -1)).to include(video.id.to_s)
    end

    it "does not touch the feed for a non-ready video's visibility change" do
      video = create(:video, :processing)

      video.update!(visibility: "private")

      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)
    end
  end

  describe ".related_to" do
    it "returns cross-channel videos sharing a tag, excluding itself and non-discoverable matches" do
      tag = create(:tag)
      video = create(:video, tags: [ tag ])
      other_channel_video = create(:video, tags: [ tag ])
      unrelated_video = create(:video)
      private_video_with_tag = create(:video, :hidden, tags: [ tag ])

      related_ids = Video.related_to(video)[:videos].map(&:id)

      expect(related_ids).to include(other_channel_video.id)
      expect(related_ids).not_to include(video.id, unrelated_video.id, private_video_with_tag.id)
    end

    it "returns empty when the video has no tags" do
      video = create(:video)
      expect(Video.related_to(video)).to eq(videos: [], views_by_video: {}, likes_by_video: {})
    end
  end

  describe "#next_hls_version" do
    it "is 1 with no playlists" do
      expect(create(:video).next_hls_version).to eq(1)
    end

    it "increments per existing version" do
      video = create(:video)
      video.video_playlists.create!(master_file_url: "http://example.com/v1/master.m3u8", version: 1, is_active: true)

      expect(video.next_hls_version).to eq(2)
    end
  end

  describe "#hls_output_prefix" do
    it "builds videos/{id}/hls/v{n}/ for a given version" do
      video = create(:video)
      expect(video.hls_output_prefix(3)).to eq("videos/#{video.id}/hls/v3/")
    end

    it "defaults to next_hls_version when no version is given" do
      video = create(:video)
      expect(video.hls_output_prefix).to eq("videos/#{video.id}/hls/v1/")
    end
  end

  describe "#purge_remote_storage" do
    it "deletes the R2 prefix on destroy" do
      video = create(:video)
      collection = double(batch_delete!: true)
      expect(S3_BUCKET).to receive(:objects).with(prefix: "videos/#{video.id}/").and_return(collection)

      video.destroy
    end
  end

  describe "#broadcast_in_process_update" do
    it "fires a Turbo Stream replace on every AASM transition, not just completion" do
      video = create(:video, :upload_pending)

      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:once)

      video.mark_as_uploaded!
    end
  end

  describe ".recent_ready_ids" do
    it "bootstraps from a cold Redis cache via a live query" do
      video = create(:video)
      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)

      ids = Video.recent_ready_ids(limit: 10)

      expect(ids).to include(video.id)
      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to be > 0
    end

    it "reads from the sorted set once warm" do
      video = create(:video)
      video.add_to_home_feed_cache

      expect(Video.recent_ready_ids(limit: 10)).to eq([ video.id ])
    end
  end
end
