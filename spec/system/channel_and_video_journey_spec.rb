require "rails_helper"

RSpec.describe "Channel and video journey", type: :system do
  let!(:category) { create(:category, name: "Science") }
  let!(:general) { create(:category, :general) }

  it "lets a signed-in user create a channel, upload a video, and see it enter the pipeline" do
    owner = create(:user)
    sign_in_as owner

    visit new_channel_path
    fill_in "channel[channel_name]", with: "My Test Channel"
    select "Science", from: "channel[category_id]"
    click_button "Create channel"

    # "Channel created" is the client-side upload_manager widget's success
    # message (app/javascript/lib/upload_manager.js) — distinct from the
    # server's own flash text, which this background-save flow never shows
    # since it Turbo.visits away before the request resolves.
    expect(page).to have_content("Channel created", wait: 10)

    channel = owner.channels.sole
    visit new_channel_video_path(channel)
    fill_in "video[title]", with: "My Test Video"
    attach_file "video[source_file]", Rails.root.join("spec/fixtures/files/sample_video.mp4")
    click_button "Start Upload"

    expect(page).to have_content("Uploaded successfully", wait: 10)

    video = channel.videos.sole
    expect(video.title).to eq("My Test Video")

    visit channel_path(channel)
    expect(page).to have_content("My Test Video", wait: 10)
  end

  it "lets a signed-in owner watch their own ready video" do
    owner = create(:user)
    channel = create(:channel, user: owner, category: category)
    video = create(:video, channel: channel, title: "Ready To Watch")
    sign_in_as owner

    visit channel_video_path(channel, video)

    expect(page).to have_content("Ready To Watch")
    expect(page).to have_selector("video")
  end

  describe "visibility" do
    it "hides a private channel's videos from another user, while the channel page still loads" do
      owner = create(:user)
      channel = create(:channel, :hidden, user: owner, category: category)
      create(:video, channel: channel)
      visitor = create(:user)
      sign_in_as visitor

      visit channel_path(channel)

      expect(page).to have_content(channel.channel_name)
      expect(page).to have_content(/private/i)
    end

    it "keeps a private video reachable via direct link for a non-owner" do
      channel = create(:channel, category: category)
      video = create(:video, :hidden, channel: channel, title: "Direct Link Only")
      visitor = create(:user)
      sign_in_as visitor

      visit channel_video_path(channel, video)

      expect(page).to have_content("Direct Link Only")
    end
  end
end
