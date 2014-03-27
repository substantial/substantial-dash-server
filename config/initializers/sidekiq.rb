namespace = "#{REDIS_NAMESPACE}-sidekiq"

Sidekiq.configure_server do |config|
  config.redis = { namespace: namespace, url: REDIS_URL }
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: namespace, url: REDIS_URL }
end
