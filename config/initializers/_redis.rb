# This Redis initializer must load early before dependencies
# like OmniAuth & Sidekiq.

REDIS_NAMESPACE = "dash-#{Rails.env.downcase}"
$redis = Redis::Namespace.new(REDIS_NAMESPACE)
