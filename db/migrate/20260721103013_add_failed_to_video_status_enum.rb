class AddFailedToVideoStatusEnum < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :video_status, 'failed'
  end
end
