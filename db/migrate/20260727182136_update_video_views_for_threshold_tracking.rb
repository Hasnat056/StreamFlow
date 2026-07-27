class UpdateVideoViewsForThresholdTracking < ActiveRecord::Migration[8.1]
  def change
    remove_index :video_views, column: [ :user_id, :video_id ]
    change_column_null :video_views, :user_id, true
  end
end
