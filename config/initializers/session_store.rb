# Be sure to restart your server when you modify this file.

Rails.application.config.session_store = :redis_session_store, {
  :key          => '_substantial-dash-server_session',
  :redis        => {
    :expire_after => 12.hours,
    :key_prefix => "#{REDIS_NAMESPACE}-session"
  }
}
