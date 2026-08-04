class Tag < ApplicationRecord
  has_many :category_tags, dependent: :destroy
  has_many :categories, through: :category_tags
  has_many :channel_tags, dependent: :destroy
  has_many :channels, through: :channel_tags
  has_many :video_tags, dependent: :destroy
  has_many :videos, through: :video_tags

  validates :name, presence: true, uniqueness: true

  after_commit { Category.bust_tag_groups_cache }
end
