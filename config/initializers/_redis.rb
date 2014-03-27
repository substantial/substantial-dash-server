# This Redis initializer must load early before dependencies
# like OmniAuth & Sidekiq.

$redis = Redis::Namespace.new(REDIS_NAMESPACE, redis: Redis.new(url: REDIS_URL))
