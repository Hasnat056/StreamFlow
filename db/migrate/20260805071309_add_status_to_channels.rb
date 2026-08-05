class AddStatusToChannels < ActiveRecord::Migration[8.1]
  def change
    create_enum :channel_statuses, %w[active paused inactive]
    add_column :channels, :status, :enum, enum_type: "channel_statuses", null: false, default: "active"
    add_column :channels, :paused_at, :datetime
  end
end
