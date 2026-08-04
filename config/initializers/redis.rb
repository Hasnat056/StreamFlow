# config/initializers/redis.rb
#
# Separate from Rails.cache: used only where a raw Redis primitive is needed
# that ActiveSupport::Cache doesn't expose (e.g. sorted sets for the home
# feed's ordered/paginated id index). Rails.cache should always be preferred
# for plain get/write/fetch caching.
REDIS = Redis.new(url: Rails.application.credentials.dig(:redis, :redis_url) || "redis://localhost:6379/1")
