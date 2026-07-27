class VideoView < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :video
end
