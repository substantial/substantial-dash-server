namespace = "dash-#{Rails.env.downcase}"
$redis = Redis::Namespace.new(namespace, :redis => Redis.new)
