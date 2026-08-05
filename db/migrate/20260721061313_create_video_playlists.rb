class CreateVideoPlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :video_playlists do |t|
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.text :master_file_url, null: false
      t.integer :version, default: 1, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
    add_index :video_playlists, [ :master_file_url, :version ], unique: true
  end
end
