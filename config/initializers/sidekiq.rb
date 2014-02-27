namespace = "dash-sidekiq-#{Rails.env.downcase}"

Sidekiq.configure_server do |config|
  config.redis = { namespace: namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: namespace }
end
