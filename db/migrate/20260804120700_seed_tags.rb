class SeedTags < ActiveRecord::Migration[8.1]
  class Tag < ActiveRecord::Base
  end

  TAG_NAMES = [
    # Gaming
    "FPS", "RPG", "Strategy", "Battle Royale", "Speedrun",
    "Walkthrough", "Esports", "Retro Gaming", "Mobile Gaming", "Indie Games",

    # Technology & Science
    "Programming", "AI & Machine Learning", "Gadget Review", "Space", "Physics",
    "Robotics", "Cybersecurity", "Open Source", "Hardware Build", "Biology",

    # Education
    "Tutorial", "Lecture", "Exam Prep", "Language Learning", "Math",
    "History", "Study Tips", "Coding Bootcamp", "Career Advice", "Documentary",

    # Entertainment
    "Comedy", "Reaction", "Prank", "Celebrity", "Movie Review",
    "TV Recap", "Animation", "Parody", "Storytime", "Drama",

    # Music
    "Cover", "Original Song", "Live Performance", "Music Production", "Lyrics",
    "Remix", "Instrumental", "Album Review", "Concert", "Songwriting",

    # News & Politics
    "Analysis", "Interview", "Debate", "Local News", "World News",
    "Economy", "Opinion", "Fact Check", "Government",

    # Sports
    "Highlights", "Match Recap", "Training", "Fitness", "Football",
    "Basketball", "Cricket", "Extreme Sports", "Athlete Interview", "Sports Analysis",

    # Vlogs & Lifestyle
    "Daily Vlog", "Travel", "Food", "Fashion", "Home & Decor",
    "Wellness", "Relationship", "Minimalism", "Day In The Life",

    # Howto & Style
    "DIY", "Beauty Tutorial", "Life Hack", "Cooking Recipe", "Repair Guide",
    "Product Review", "Styling Tips", "Budget Tips", "Home Improvement", "Skill Building",

    # General (hidden category, always included in every pool)
    "Funny", "Beginner Friendly", "Advanced", "Short Form", "Long Form",
    "Behind The Scenes", "Collaboration", "Weekly Series", "Q&A", "Tips & Tricks", "Review"
  ].freeze

  def up
    TAG_NAMES.each { |name| Tag.create!(name: name) }
  end

  def down
    Tag.delete_all
  end
end
