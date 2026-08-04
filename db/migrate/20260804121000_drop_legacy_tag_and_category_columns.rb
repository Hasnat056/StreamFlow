class DropLegacyTagAndCategoryColumns < ActiveRecord::Migration[8.1]
  def change
    # Superseded by channels.category_id (Category association)
    remove_column :channels, :category, :string, null: false
    # Superseded by the channel_tags join table. Also a hard requirement, not
    # just cleanup: Channel#has_many :tags, through: :channel_tags would
    # collide with the auto-generated accessor for this text[] column.
    remove_column :channels, :tags, :text, default: [], null: false, array: true
    # Same collision reason, for Video#has_many :tags, through: :video_tags.
    remove_column :videos, :tags, :text, default: [], null: false, array: true

    change_column_null :channels, :category_id, false
  end
end
