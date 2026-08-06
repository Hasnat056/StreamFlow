FactoryBot.define do
  factory :comment do
    user
    video
    comment_text { "Great video!" }
  end
end
