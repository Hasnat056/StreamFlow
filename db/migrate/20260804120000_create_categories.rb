class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.boolean :is_visible, null: false, default: true

      t.timestamps
    end
    add_index :categories, :name, unique: true
  end
end
