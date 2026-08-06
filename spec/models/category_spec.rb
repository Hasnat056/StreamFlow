require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to have_many(:category_tags) }
  it { is_expected.to have_many(:tags) }

  describe ".general" do
    it "finds the row named General" do
      general = create(:category, :general)
      expect(Category.general).to eq(general)
    end
  end

  describe ".cached_tag_groups" do
    it "returns [category, tags] pairs, hidden category included, sorted visible-first then by name" do
      general = create(:category, :general)
      zeta = create(:category, name: "Zeta")
      alpha = create(:category, name: "Alpha")
      tag = create(:tag)
      create(:category_tag, category: alpha, tag: tag)

      groups = Category.cached_tag_groups

      expect(groups.map(&:first)).to eq([ alpha, zeta, general ])
      expect(groups.find { |category, _| category == alpha }.last).to eq([ tag ])
    end

    it "is busted when a Category is saved" do
      Category.cached_tag_groups
      create(:category, name: "New Category")

      expect(Category.cached_tag_groups.map(&:first).map(&:name)).to include("New Category")
    end

    it "is busted when a Tag is saved" do
      category = create(:category)
      Category.cached_tag_groups

      tag = create(:tag)
      create(:category_tag, category: category, tag: tag)

      expect(Category.cached_tag_groups.find { |c, _| c == category }.last).to include(tag)
    end
  end
end
