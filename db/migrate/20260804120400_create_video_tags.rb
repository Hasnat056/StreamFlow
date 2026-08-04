class CreateVideoTags < ActiveRecord::Migration[8.1]
  def change
    create_table :video_tags do |t|
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :video_tags, [ :video_id, :tag_id ], unique: true
  end
end
