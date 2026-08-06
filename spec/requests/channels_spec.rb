require "rails_helper"

RSpec.describe "Channels", type: :request do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:category) { create(:category) }
  let(:public_channel) { create(:channel, user: owner, category: category) }
  let(:private_channel) { create(:channel, :hidden, user: other, category: category) }

  describe "GET /channels/:id (show)" do
    it "renders the management video list for the owner" do
      create(:video, channel: public_channel)
      sign_in_as owner

      get channel_path(public_channel)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("mlist")
    end

    it "renders discoverable videos and the subscriber count for a visitor of a public channel" do
      create(:video, channel: public_channel)

      get channel_path(public_channel)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("video-grid")
      expect(response.body).to match(/subscriber/)
    end

    it "renders the header with a private notice and no video list for a visitor of a private channel" do
      get channel_path(private_channel)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(private_channel.channel_name)
      expect(response.body).to match(/private/i)
      expect(response.body).not_to include("video-grid")
      expect(response.body).not_to include("mlist")
    end

    it "404s for an unknown handle" do
      get channel_path("does_not_exist")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /channels/new and POST /channels (create)" do
    it "requires authentication" do
      get new_channel_path
      expect(response).to redirect_to(root_path)

      expect { post channels_path, params: { channel: { channel_name: "X" } } }.not_to change(Channel, :count)
      expect(response).to redirect_to(root_path)
    end

    it "ignores a submitted handle param and generates one instead" do
      sign_in_as owner

      post channels_path, params: {
        channel: {
          channel_name: "Brand New Channel",
          category_id: category.id,
          handle: "hacker_chosen"
        }
      }

      expect(Channel.order(:id).last.handle).to eq("brand_new_channel")
    end

    it "re-renders :new with errors on invalid params" do
      sign_in_as owner

      expect {
        post channels_path, params: { channel: { channel_name: "" } }
      }.not_to change(Channel, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /channels/:id/edit" do
    it "is denied for a non-owner" do
      sign_in_as other

      get edit_channel_path(public_channel)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /channels/:id (update)" do
    it "succeeds for the owner" do
      sign_in_as owner

      patch channel_path(public_channel), params: { channel: { channel_name: "Updated Name" } }

      expect(response).to redirect_to(channel_path(public_channel.reload))
      expect(public_channel.reload.channel_name).to eq("Updated Name")
    end

    it "is denied for a non-owner" do
      sign_in_as other

      patch channel_path(public_channel), params: { channel: { channel_name: "Hijacked Name" } }

      expect(response).to redirect_to(root_path)
      expect(public_channel.reload.channel_name).not_to eq("Hijacked Name")
    end

    it "rejects a tag outside the channel's category/General pool" do
      sign_in_as owner
      outside_tag = create(:tag)
      create(:category_tag, category: create(:category), tag: outside_tag)

      patch channel_path(public_channel), params: { channel: { tag_ids: [ outside_tag.id ] } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(public_channel.reload.tags).not_to include(outside_tag)
    end
  end
end
