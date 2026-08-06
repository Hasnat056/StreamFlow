FactoryBot.define do
  factory :watch_progress do
    user
    video
    last_timestamp_sec { 60 }
  end
end
