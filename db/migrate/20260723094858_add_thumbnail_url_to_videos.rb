class AddThumbnailUrlToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :thumbnail_url, :text
  end
end
