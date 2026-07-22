class AddSourceFilePathToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :source_file_path, :text, null: false
  end
end
