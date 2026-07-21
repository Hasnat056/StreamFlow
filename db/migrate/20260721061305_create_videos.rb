class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_enum :video_status, %w[upload_pending uploaded processing ready]
    create_table :videos do |t|
      t.references :channel, null: false, foreign_key: {on_delete: :cascade}
      t.string :title, null: false
      t.text :description
      t.text :tags, array: true, default: [], null: false
      t.text :thumbnail_url, null: false
      t.string :content_type, null: false
      t.enum :status, enum_type: :video_status, null: false, default: 'upload_pending'

      t.timestamps
    end
  end
end