class RemoveChannelTypeAndStatusAddVisibility < ActiveRecord::Migration[8.1]
  def change
    remove_index :channels, name: "index_channels_on_user_id_and_channel_type"
    remove_column :channels, :channel_type, :enum, enum_type: "channel_types", default: "viewer", null: false
    remove_column :channels, :status, :enum, enum_type: "channel_statuses", default: "active", null: false
    remove_column :channels, :paused_at, :datetime
    drop_enum :channel_types, %w[viewer creator]
    drop_enum :channel_statuses, %w[active paused inactive]

    create_enum :channel_visibilities, %w[public private]
    add_column :channels, :visibility, :enum, enum_type: "channel_visibilities", null: false, default: "public"

    change_column_null :channels, :category_id, false
  end
end
