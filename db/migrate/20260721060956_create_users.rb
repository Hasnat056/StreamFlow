class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext" unless extension_enabled?("citext")
    create_table :users do |t|
      t.string :username, null: false
      t.string :uid, null: false
      t.string :provider, null: false
      t.citext :email, null: false
      t.text :avatar_url

      t.timestamps
    end
    add_index :users, [:provider,:uid], unique: true
    add_index :users , :email, unique: true
  end
end