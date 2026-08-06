FactoryBot.define do
  factory :channel do
    sequence(:channel_name) { |n| "Channel #{n}" }
    visibility { "public" }
    user
    category

    trait :hidden do
      visibility { "private" }
    end
  end
end
