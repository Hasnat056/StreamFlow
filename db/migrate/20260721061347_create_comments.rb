class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.text :comment_text, null: false
      t.integer :likes, default: 0, null: false

      t.timestamps
    end
    add_index :comments, [ :user_id, :video_id ], unique: true
  end
end
