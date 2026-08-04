class CreateCategoryTags < ActiveRecord::Migration[8.1]
  def change
    create_table :category_tags do |t|
      t.references :category, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :category_tags, [ :category_id, :tag_id ], unique: true
  end
end
