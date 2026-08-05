class AddVisibilityToVideos < ActiveRecord::Migration[8.1]
  def change
    create_enum :video_visibilities, %w[public private]
    add_column :videos, :visibility, :enum, enum_type: "video_visibilities", null: false, default: "public"
  end
end
