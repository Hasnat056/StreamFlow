class CategoryTag < ApplicationRecord
  belongs_to :category
  belongs_to :tag

  after_commit { Category.bust_tag_groups_cache }
end
