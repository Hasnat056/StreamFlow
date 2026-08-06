FactoryBot.define do
  factory :user do
    provider { "google_oauth2" }
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
  end
end
