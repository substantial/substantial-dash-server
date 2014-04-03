module FayeChannelBuffer
  def self.key(public_channel)
    "faye-channel-buffer:#{public_channel.underscore.dasherize}"
  end
end
