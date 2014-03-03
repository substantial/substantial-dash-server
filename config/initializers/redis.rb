REDIS_NAMESPACE = "dash-#{Rails.env.downcase}"
$redis = Redis::Namespace.new(REDIS_NAMESPACE, :redis => Redis.new)
