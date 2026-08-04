class CreateChannelTags < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_tags do |t|
      t.references :channel, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :channel_tags, [ :channel_id, :tag_id ], unique: true
  end
end
