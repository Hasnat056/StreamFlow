require "rails_helper"

RSpec.describe Channel, type: :model do
  it { is_expected.to validate_presence_of(:channel_name) }
  it { is_expected.to validate_presence_of(:category_id) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:category) }
  it { is_expected.to have_many(:videos) }
  it { is_expected.to have_many(:subscriptions) }

  describe "handle generation" do
    it "generates a handle from channel_name on create" do
      channel = create(:channel, channel_name: "Brand New Channel")
      expect(channel.handle).to eq("brand_new_channel")
    end

    it "slugifies punctuation and spacing into underscores" do
      channel = create(:channel, channel_name: "Hasnat's Tech Corner!!")
      expect(channel.handle).to eq("hasnat_s_tech_corner")
    end

    it "falls back to channel as the base when the slugified name is under 3 characters" do
      channel = create(:channel, channel_name: "A!")
      expect(channel.handle).to eq("channel")
    end

    it "appends a numeric suffix when the generated handle collides with an existing one" do
      create(:channel, channel_name: "Collision Test")
      second = create(:channel, channel_name: "Collision Test")
      expect(second.handle).to eq("collision_test_1")
    end

    it "ignores a manually assigned handle and generates one anyway" do
      channel = create(:channel, channel_name: "Manual Handle Attempt", handle: "hacker_chosen")
      expect(channel.handle).to eq("manual_handle_attempt")
    end

    it "does not change the handle on update" do
      channel = create(:channel)
      original_handle = channel.handle

      channel.update!(channel_name: "Renamed Channel")

      expect(channel.reload.handle).to eq(original_handle)
    end
  end

  describe "visibility" do
    it "defaults to public" do
      expect(build(:channel)).to be_visible
    end
  end

  describe "#tag_pool" do
    it "includes the channel's own category plus the General category" do
      science = create(:category, name: "Science")
      general = create(:category, :general)
      astronomy = create(:tag)
      comedy = create(:tag)
      create(:category_tag, category: science, tag: astronomy)
      create(:category_tag, category: general, tag: comedy)
      channel = create(:channel, category: science)

      expect(channel.tag_pool).to contain_exactly(astronomy, comedy)
    end
  end

  describe "tag validations" do
    it "rejects more than MAX_TAGS tags" do
      channel = create(:channel)
      extra_tags = Array.new(Channel::MAX_TAGS + 1) do
        tag = create(:tag)
        create(:category_tag, category: channel.category, tag: tag)
        tag
      end

      channel.tags = extra_tags

      expect(channel).not_to be_valid
      expect(channel.errors[:tags]).to include("can have at most #{Channel::MAX_TAGS}")
    end

    it "rejects a tag outside the channel's category or General" do
      channel = create(:channel)
      outside_tag = create(:tag)
      create(:category_tag, category: create(:category), tag: outside_tag)

      channel.tags = [ outside_tag ]

      expect(channel).not_to be_valid
      expect(channel.errors[:tags]).to include("must belong to the selected category or General")
    end
  end

  describe ".cached_attrs" do
    it "returns the channel with category and tags preloaded" do
      channel = create(:channel)

      cached = Channel.cached_attrs(channel.handle)

      expect(cached.id).to eq(channel.id)
      expect(cached.association(:category)).to be_loaded
      expect(cached.association(:tags)).to be_loaded
    end

    it "is busted when the channel is saved" do
      channel = create(:channel)
      Channel.cached_attrs(channel.handle)

      channel.update!(channel_name: "Freshly Renamed")

      expect(Channel.cached_attrs(channel.handle).channel_name).to eq("Freshly Renamed")
    end

    it "returns nil for an unknown handle without poisoning the cache" do
      expect(Channel.cached_attrs("does_not_exist")).to be_nil
      expect(Rails.cache.exist?("channel:does_not_exist:attrs")).to be false
    end
  end

  describe ".cached_subscriber_count" do
    it "reflects the real Subscription count" do
      channel = create(:channel)
      create(:subscription, channel: channel)

      expect(Channel.cached_subscriber_count(channel.id)).to eq(1)
    end
  end

  # The handle is system-assigned and attr_readonly, so these validations
  # can never be reached through normal application code (Rails raises
  # ActiveRecord::ReadonlyAttributeError on any attempt to write `handle`
  # directly). Forcing a bad value via update_all (a raw SQL UPDATE that
  # bypasses the readonly guard entirely) + reload is the only way to reach
  # them, and confirms the validations still hold as a defense-in-depth
  # backstop even though the generator itself can't produce an invalid value.
  describe "handle validations (forced past generation)" do
    def force_handle(channel, value)
      Channel.where(id: channel.id).update_all(handle: value)
      channel.reload
    end

    it "rejects a non [a-z0-9_] handle if forced" do
      channel = force_handle(create(:channel), "Bad-Handle!")
      expect(channel).not_to be_valid
      expect(channel.errors[:handle]).to include("can only contain lowercase letters, numbers, and underscores")
    end

    it "rejects a duplicate handle if forced (case-insensitive)" do
      existing = create(:channel)
      channel = force_handle(create(:channel), existing.handle.upcase)
      expect(channel).not_to be_valid
      expect(channel.errors[:handle]).to include("has already been taken")
    end

    it "rejects a handle under 3 characters if forced" do
      channel = force_handle(create(:channel), "ab")
      expect(channel).not_to be_valid
      expect(channel.errors[:handle]).to include("is too short (minimum is 3 characters)")
    end

    it "rejects a handle over 30 characters if forced" do
      channel = force_handle(create(:channel), "a" * 31)
      expect(channel).not_to be_valid
      expect(channel.errors[:handle]).to include("is too long (maximum is 30 characters)")
    end

    it "rejects 'new' as a handle if forced" do
      channel = force_handle(create(:channel), "new")
      expect(channel).not_to be_valid
      expect(channel.errors[:handle]).to include("is reserved")
    end
  end

  describe "#sync_videos_on_visibility_change" do
    it "busts each ready video's attrs cache and removes it from the home feed when the channel goes private" do
      channel = create(:channel)
      video = create(:video, channel: channel)
      video.add_to_home_feed_cache
      Video.cached_attrs(video.id)

      channel.update!(visibility: "private")

      expect(Rails.cache.exist?("video:#{video.id}:attrs")).to be false
      expect(REDIS.zcard(Video::HOME_FEED_KEY)).to eq(0)
    end

    it "adds ready videos back to the home feed when the channel goes public again" do
      channel = create(:channel, :hidden)
      video = create(:video, channel: channel)

      channel.update!(visibility: "public")

      expect(REDIS.zrange(Video::HOME_FEED_KEY, 0, -1)).to include(video.id.to_s)
    end
  end

  describe "dependent destroy" do
    it "destroys its videos, subscriptions, and channel_tags" do
      channel = create(:channel)
      create(:video, channel: channel)
      create(:subscription, channel: channel)
      create(:channel_tag, channel: channel)

      expect { channel.destroy }.to change(Video, :count).by(-1)
        .and change(Subscription, :count).by(-1)
        .and change(ChannelTag, :count).by(-1)
    end
  end

  describe "#to_param" do
    it "returns the handle" do
      channel = create(:channel)
      expect(channel.to_param).to eq(channel.handle)
    end
  end
end
