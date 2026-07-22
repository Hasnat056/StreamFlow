# frozen_string_literal: true

class Channel < ApplicationRecord
  CATEGORIES = [
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
  # Relationships
  belongs_to :user
  has_many :videos, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  # Validations
  validates :channel_name, presence: true
  validates :category, presence: true
  validates :user_id, presence: true

  # Ensure user can only have one channel per channel_type (per index constraint)
  validates :channel_type, presence: true,
            uniqueness: { scope: :user_id, message: "already has a channel of this type" }

  # Normalizes comma-separated string inputs for tags into a PostgreSQL array
  def tags_input=(value)
    if value.is_a?(String)
      self.tags = value.split(",").map(&:strip).reject(&:blank?)
    elsif value.is_a?(Array)
      self.tags = value
    end
  end

  # Helper to display tags back as a comma-separated string in forms
  def tags_input
    tags&.join(", ")
  end
end