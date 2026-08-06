FactoryBot.define do
  factory :video do
    sequence(:title) { |n| "Video #{n}" }
    status { "ready" }
    visibility { "public" }
    duration_sec { 300 }
    watch_time { 0 }
    channel

    trait :hidden do
      visibility { "private" }
    end

    trait :processing do
      status { "processing" }
    end

    trait :upload_pending do
      status { "upload_pending" }
    end
  end
end
