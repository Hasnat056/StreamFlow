class AddWatchTimeToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :watch_time, :bigint, null: false, default: 0
  end
end
