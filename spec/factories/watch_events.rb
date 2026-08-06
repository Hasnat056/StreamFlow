FactoryBot.define do
  factory :watch_event do
    video
    user
    seconds_watched { 5 }
  end
end
