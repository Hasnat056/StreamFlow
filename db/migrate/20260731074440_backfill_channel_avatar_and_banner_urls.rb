class BackfillChannelAvatarAndBannerUrls < ActiveRecord::Migration[8.1]
  def up
    base_url = Rails.application.credentials.dig(:r2, :public_base_url)
    return if base_url.blank?

    Channel.includes(avatar_attachment: :blob, banner_attachment: :blob).find_each do |channel|
      updates = {}
      updates[:channel_avatar_url] = "#{base_url}/#{channel.avatar.blob.key}" if channel.avatar.attached?
      updates[:channel_banner_url] = "#{base_url}/#{channel.banner.blob.key}" if channel.banner.attached?
      channel.update_columns(updates) if updates.present?
    end
  end

  def down
    # Data backfill only - nothing to reverse.
  end
end
