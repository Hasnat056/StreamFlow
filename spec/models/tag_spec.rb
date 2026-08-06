require "rails_helper"

RSpec.describe Tag, type: :model do
  subject { build(:tag) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to have_many(:categories) }
  it { is_expected.to have_many(:channels) }
  it { is_expected.to have_many(:videos) }

  it "busts Category's tag-groups cache on save" do
    Category.cached_tag_groups
    tag = build(:tag)

    expect { tag.save! }.not_to raise_error
    expect(Rails.cache.exist?(Category::TAG_GROUPS_CACHE_KEY)).to be false
  end
end
