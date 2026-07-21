class CreateVideoViews < ActiveRecord::Migration[8.1]
  def change
    create_table :video_views do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.references :video, null: false, foreign_key: {on_delete: :cascade}
      t.inet :ip_address, null: false
      t.text :session_token

      t.datetime :created_at, null: false
    end
    add_index :video_views, [:user_id, :video_id], unique: true
  end
end