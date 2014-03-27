Rails.application.config.middleware.use OmniAuth::Builder do
  # The Redis store namespaces itself in "openid-store:"
  provider :google_apps, {
    domain: 'substantial.com', 
    store: OpenID::Store::Redis.new($redis)
  }
end
