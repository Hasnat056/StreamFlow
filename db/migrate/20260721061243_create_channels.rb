class CreateChannels < ActiveRecord::Migration[8.1]
  def change
    create_enum :channel_types, %w[viewer creator]
    create_table :channels do |t|
      t.references :user, null: false, foreign_key: {on_delete: :nullify}
      t.string :channel_name, null: false
      t.enum :channel_type, enum_type: "channel_types", null: false, default: 'viewer'
      t.string :category, null: false
      t.text :description
      t.text :tags, array: true, default: [], null: false
      t.text :channel_avatar_url
      t.text :channel_banner_url

      t.timestamps
    end
    add_index :channels, [:user_id, :channel_type], unique: true
  end
end