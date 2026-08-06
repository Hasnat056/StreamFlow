FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    is_visible { true }

    trait :general do
      name { "General" }
      is_visible { false }
    end
  end
end
