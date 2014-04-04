require 'spec_helper'
require 'faye_channel_buffer'
require 'on_publish_set_buffer'

describe OnPublishSetBuffer do
  subject { OnPublishSetBuffer.new }
  let(:callback) { ->(message) {} }

  describe "for regular channel messages" do
    let(:message) do
      { 
        'channel' => '/awesomeness',
        'data' => '{ "foo": "barsworth" }'
      }
    end
    let(:buffer_key) { FayeChannelBuffer.key(message['channel']) }

    it "sets the channel's buffer" do
      Redis.any_instance.should_receive(:set)
        .with("#{REDIS_NAMESPACE}:#{buffer_key}", message['data'], { ex: 3600 })
      subject.incoming(message, callback)
    end

    it "passes the message" do
      callback_was_called = false
      callback = ->(message) { callback_was_called = true }
      subject.incoming(message, callback)
      expect(callback_was_called).to be_true
    end
  end

  describe "for Bayeux protocol messages" do
    let(:message) do
      { 
        'channel' => '/meta/subscribe'
      }
    end

    it "passes the message" do
      Redis.any_instance.should_not_receive(:set)
      callback_was_called = false
      callback = ->(message) { callback_was_called = true }
      subject.incoming(message, callback)
      expect(callback_was_called).to be_true
    end
  end

  describe "for personal messages" do
    let(:message) do
      { 
        'channel' => '/personal/anything'
      }
    end

    it "passes the message" do
      Redis.any_instance.should_not_receive(:set)
      callback_was_called = false
      callback = ->(message) { callback_was_called = true }
      subject.incoming(message, callback)
      expect(callback_was_called).to be_true
    end
  end
end
