class CreateVideoLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :video_likes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :video, null: false, foreign_key: { on_delete: :cascade }

      t.datetime :created_at, null: false
    end
    add_index :video_likes, [ :user_id, :video_id ], unique: true
  end
end
