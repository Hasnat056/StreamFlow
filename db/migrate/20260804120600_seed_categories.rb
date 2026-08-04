class SeedCategories < ActiveRecord::Migration[8.1]
  class Category < ActiveRecord::Base
  end

  VISIBLE_CATEGORIES = [
    "Gaming",
    "Technology & Science",
    "Education",
    "Entertainment",
    "Music",
    "News & Politics",
    "Sports",
    "Vlogs & Lifestyle",
    "Howto & Style"
  ].freeze

  def up
    VISIBLE_CATEGORIES.each { |name| Category.create!(name: name, is_visible: true) }
    Category.create!(name: "General", is_visible: false)
  end

  def down
    Category.delete_all
  end
end
