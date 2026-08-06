require "rails_helper"

RSpec.describe CategoryTag, type: :model do
  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:tag) }

  it "busts Category's tag-groups cache on save" do
    category = create(:category)
    tag = create(:tag)
    Category.cached_tag_groups

    create(:category_tag, category: category, tag: tag)

    expect(Rails.cache.exist?(Category::TAG_GROUPS_CACHE_KEY)).to be false
  end
end
