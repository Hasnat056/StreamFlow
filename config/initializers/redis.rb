# config/initializers/redis.rb
#
# Separate from Rails.cache: used only where a raw Redis primitive is needed
# that ActiveSupport::Cache doesn't expose (e.g. sorted sets for the home
# feed's ordered/paginated id index). Rails.cache should always be preferred
# for plain get/write/fetch caching.

if Rails.env.test?
  # Deliberately never touches Rails.application.credentials here, same as
  # config/database.yml's test entry never does for Postgres — test config
  # shouldn't depend on the (possibly missing, possibly pointing at a real
  # dev/prod instance) encrypted credentials at all.
  redis_url = ENV["REDIS_URL"] || "redis://localhost:6379/1"

  # test_helper.rb parallelizes Minitest across OS processes, and Rails sets
  # TEST_ENV_NUMBER per worker ("" for the first, "2", "3", ... after that) —
  # the same value it uses to give each worker its own Postgres test database.
  # Without an equivalent split here, every worker would read/write the same
  # Redis keys (home:recent_video_ids) and corrupt each other's assertions.
  worker_offset = ENV["TEST_ENV_NUMBER"].presence&.to_i || 0
  redis_url = redis_url.sub(%r{/\d+\z}, "/#{2 + worker_offset}")
else
  redis_url = ENV["REDIS_CACHE_URL"] || Rails.application.credentials.dig(:redis, :redis_url) || "redis://localhost:6379/1"
end

REDIS = Redis.new(url: redis_url)
