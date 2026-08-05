class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :channel, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :subscriptions, [ :user_id, :channel_id ], unique: true
  end
end
