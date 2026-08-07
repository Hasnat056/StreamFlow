redis_url = ENV["REDIS_QUEUE_URL"] || Rails.application.credentials.dig(:redis, :redis_url)

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  config.on(:startup) do
    Sidekiq::Cron::Job.create(
      name: "watch_time_rollup",
      cron: "*/10 * * * *",
      class: "WatchTimeRollupJob"
    )
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
