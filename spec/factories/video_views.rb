FactoryBot.define do
  factory :video_view do
    video
    user
    ip_address { "127.0.0.1" }
  end
end
