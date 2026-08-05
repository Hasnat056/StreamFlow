class CreateWatchProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :watch_progresses do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.integer :last_timestamp_sec, null: false

      t.datetime :updated_at, null: false
    end
    add_index :watch_progresses, [ :user_id, :video_id ], unique: true
  end
end
