class RemoveActiveStorageRedundantFieldsFromVideos < ActiveRecord::Migration[8.1]
  def change
    remove_column :videos, :source_file_path, :text
    remove_column :videos, :content_type, :string
    remove_column :videos, :thumbnail_url, :text
  end
end
