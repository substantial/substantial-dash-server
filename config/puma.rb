on_restart do
  $redis = Redis::Namespace.new(REDIS_NAMESPACE)
end
