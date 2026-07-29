class AddDurationSecToWatchProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :watch_progresses, :duration_sec, :integer, null: false, default: 0
    change_column_default :watch_progresses, :duration_sec, from: 0, to: nil
  end
end
