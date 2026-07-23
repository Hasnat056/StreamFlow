class AddProcessingErrorToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :processing_error, :text
  end
end
