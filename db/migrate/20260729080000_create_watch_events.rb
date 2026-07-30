class CreateWatchEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :watch_events do |t|
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: true, foreign_key: { on_delete: :cascade }
      t.integer :seconds_watched, null: false

      t.datetime :created_at, null: false
    end
  end
end
