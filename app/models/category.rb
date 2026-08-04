class Category < ApplicationRecord
  GENERAL_NAME = "General"
  TAG_GROUPS_CACHE_KEY = "taxonomy:tag_groups"

  has_many :category_tags, dependent: :destroy
  has_many :tags, through: :category_tags
  has_many :channels, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  scope :visible, -> { where(is_visible: true) }

  after_commit :bust_tag_groups_cache

  def self.general
    find_by(name: GENERAL_NAME)
  end

  # [[category, tags], ...] for every category (including the hidden General
  # one), used by every tag-picker view in the app. Reference data that only
  # changes via rare admin/seed writes, so it's cached indefinitely and
  # invalidated explicitly (see bust_tag_groups_cache below and the matching
  # after_commit hooks on Tag/CategoryTag) rather than on a TTL.
  def self.cached_tag_groups
    Rails.cache.fetch(TAG_GROUPS_CACHE_KEY) do
      includes(:tags).order(is_visible: :desc, name: :asc).map { |category| [ category, category.tags.sort_by(&:name) ] }
    end
  end

  def self.bust_tag_groups_cache
    Rails.cache.delete(TAG_GROUPS_CACHE_KEY)
  end

  private

  def bust_tag_groups_cache
    self.class.bust_tag_groups_cache
  end
end
