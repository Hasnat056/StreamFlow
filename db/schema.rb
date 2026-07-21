# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_21_061431) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "channel_types", ["viewer", "creator"]
  create_enum "video_status", ["upload_pending", "uploaded", "processing", "ready"]

  create_table "channels", force: :cascade do |t|
    t.string "category", null: false
    t.text "channel_avatar_url"
    t.text "channel_banner_url"
    t.string "channel_name", null: false
    t.enum "channel_type", default: "viewer", null: false, enum_type: "channel_types"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "tags", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "channel_type"], name: "index_channels_on_user_id_and_channel_type", unique: true
    t.index ["user_id"], name: "index_channels_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "comment_text", null: false
    t.datetime "created_at", null: false
    t.integer "likes", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "video_id", null: false
    t.index ["user_id", "video_id"], name: "index_comments_on_user_id_and_video_id", unique: true
    t.index ["user_id"], name: "index_comments_on_user_id"
    t.index ["video_id"], name: "index_comments_on_video_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["channel_id"], name: "index_subscriptions_on_channel_id"
    t.index ["user_id", "channel_id"], name: "index_subscriptions_on_user_id_and_channel_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "avatar_url"
    t.datetime "created_at", null: false
    t.citext "email", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "video_likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.bigint "video_id", null: false
    t.index ["user_id", "video_id"], name: "index_video_likes_on_user_id_and_video_id", unique: true
    t.index ["user_id"], name: "index_video_likes_on_user_id"
    t.index ["video_id"], name: "index_video_likes_on_video_id"
  end

  create_table "video_playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.text "master_file_url", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.bigint "video_id", null: false
    t.index ["master_file_url", "version"], name: "index_video_playlists_on_master_file_url_and_version", unique: true
    t.index ["video_id"], name: "index_video_playlists_on_video_id"
  end

  create_table "video_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.inet "ip_address", null: false
    t.text "session_token"
    t.bigint "user_id", null: false
    t.bigint "video_id", null: false
    t.index ["user_id", "video_id"], name: "index_video_views_on_user_id_and_video_id", unique: true
    t.index ["user_id"], name: "index_video_views_on_user_id"
    t.index ["video_id"], name: "index_video_views_on_video_id"
  end

  create_table "videos", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.enum "status", default: "upload_pending", null: false, enum_type: "video_status"
    t.text "tags", default: [], null: false, array: true
    t.text "thumbnail_url", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_videos_on_channel_id"
  end

  create_table "watch_progresses", force: :cascade do |t|
    t.integer "last_timestamp_sec", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "video_id", null: false
    t.index ["user_id", "video_id"], name: "index_watch_progresses_on_user_id_and_video_id", unique: true
    t.index ["user_id"], name: "index_watch_progresses_on_user_id"
    t.index ["video_id"], name: "index_watch_progresses_on_video_id"
  end

  add_foreign_key "channels", "users", on_delete: :nullify
  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "comments", "videos", on_delete: :cascade
  add_foreign_key "subscriptions", "channels", on_delete: :cascade
  add_foreign_key "subscriptions", "users", on_delete: :cascade
  add_foreign_key "video_likes", "users", on_delete: :cascade
  add_foreign_key "video_likes", "videos", on_delete: :cascade
  add_foreign_key "video_playlists", "videos", on_delete: :cascade
  add_foreign_key "video_views", "users", on_delete: :cascade
  add_foreign_key "video_views", "videos", on_delete: :cascade
  add_foreign_key "videos", "channels", on_delete: :cascade
  add_foreign_key "watch_progresses", "users", on_delete: :cascade
  add_foreign_key "watch_progresses", "videos", on_delete: :cascade
end
