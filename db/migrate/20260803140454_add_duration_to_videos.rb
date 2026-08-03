class AddDurationToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :duration_sec, :integer
  end
end
