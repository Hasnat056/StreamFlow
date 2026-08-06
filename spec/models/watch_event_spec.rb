require "rails_helper"

RSpec.describe WatchEvent, type: :model do
  it { is_expected.to belong_to(:video) }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to validate_numericality_of(:seconds_watched).is_greater_than(0) }
end
