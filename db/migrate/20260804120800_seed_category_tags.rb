class SeedCategoryTags < ActiveRecord::Migration[8.1]
  class Category < ActiveRecord::Base
  end

  class Tag < ActiveRecord::Base
  end

  class CategoryTag < ActiveRecord::Base
  end

  CATEGORY_TAGS = {
    "Gaming" => [
      "FPS", "RPG", "Strategy", "Battle Royale", "Speedrun",
      "Walkthrough", "Esports", "Retro Gaming", "Mobile Gaming", "Indie Games"
    ],
    "Technology & Science" => [
      "Programming", "AI & Machine Learning", "Gadget Review", "Space", "Physics",
      "Robotics", "Cybersecurity", "Open Source", "Hardware Build", "Biology"
    ],
    "Education" => [
      "Tutorial", "Lecture", "Exam Prep", "Language Learning", "Math",
      "History", "Study Tips", "Coding Bootcamp", "Career Advice", "Documentary"
    ],
    "Entertainment" => [
      "Comedy", "Reaction", "Prank", "Celebrity", "Movie Review",
      "TV Recap", "Animation", "Parody", "Storytime", "Drama"
    ],
    "Music" => [
      "Cover", "Original Song", "Live Performance", "Music Production", "Lyrics",
      "Remix", "Instrumental", "Album Review", "Concert", "Songwriting"
    ],
    "News & Politics" => [
      "Analysis", "Interview", "Debate", "Local News", "World News",
      "Economy", "Opinion", "Fact Check", "Government"
    ],
    "Sports" => [
      "Highlights", "Match Recap", "Training", "Fitness", "Football",
      "Basketball", "Cricket", "Extreme Sports", "Athlete Interview", "Sports Analysis"
    ],
    "Vlogs & Lifestyle" => [
      "Daily Vlog", "Travel", "Food", "Fashion", "Home & Decor",
      "Wellness", "Relationship", "Minimalism", "Day In The Life"
    ],
    "Howto & Style" => [
      "DIY", "Beauty Tutorial", "Life Hack", "Cooking Recipe", "Repair Guide",
      "Product Review", "Styling Tips", "Budget Tips", "Home Improvement", "Skill Building"
    ],
    "General" => [
      "Funny", "Beginner Friendly", "Advanced", "Short Form", "Long Form",
      "Behind The Scenes", "Collaboration", "Weekly Series", "Q&A", "Tips & Tricks", "Review"
    ]
  }.freeze

  # Technology & Science and Education overlap heavily in practice
  # (programming/AI/science tutorials genuinely belong to both), so every
  # Technology & Science tag is also linked to Education rather than
  # hand-picking which ones "really" cross over.
  EXTRA_LINKS = {
    "Education" => CATEGORY_TAGS["Technology & Science"]
  }.freeze

  def up
    links = CATEGORY_TAGS.merge(EXTRA_LINKS) { |_key, base, extra| base + extra }

    links.each do |category_name, tag_names|
      category = Category.find_by!(name: category_name)
      tag_names.each do |tag_name|
        tag = Tag.find_by!(name: tag_name)
        CategoryTag.find_or_create_by!(category_id: category.id, tag_id: tag.id)
      end
    end
  end

  def down
    CategoryTag.delete_all
  end
end
