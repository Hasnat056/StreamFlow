class DropDurationFromWatchProgresses < ActiveRecord::Migration[8.1]
  def change
    remove_column :watch_progresses, :duration_sec, :integer
  end
end
