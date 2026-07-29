class CreateCommentLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_likes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :comment_likes, [ :user_id, :comment_id ], unique: true

    remove_column :comments, :likes, :integer, default: 0, null: false
  end
end
