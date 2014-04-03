require 'spec_helper'
require 'faye_channel_buffer'
require 'on_subscribe_send_buffer'

describe OnSubscribeSendBuffer do
  subject { OnSubscribeSendBuffer.new }
  let(:callback) { ->(message) {} }

  describe "for subscribe messages" do
    let(:message) do
      { 
        'channel' => '/meta/subscribe',
        'subscription' => '/awesomeness'
      }
    end

    describe "with valid API key" do
      let(:buffer_key) { FayeChannelBuffer.key(message['subscription']) }
      let(:api_key) { 'keyfoo' }
      before do
        message['ext'] = {
          'apiKey' => api_key
        }
        $redis.mapped_hmset("#{SubscriberAuth::KEY_PREFIX}#{api_key}", {
          'uid' => '55555',
          'info' => {
            'name' => 'Foo Barsmith'
          }
        })
      end
      let(:bayeux_personal_channel) { "/personal/#{api_key}#{message['subscription']}" }

      it "passes the message" do
        callback_was_called = false
        callback = ->(message) { callback_was_called = true }
        subject.incoming(message, callback)
        expect(callback_was_called).to be_true
      end

      it "reads the channel's buffer" do
        Redis.any_instance.should_receive(:get)
          .with("#{REDIS_NAMESPACE}:#{buffer_key}").and_call_original
        subject.incoming(message, callback)
      end

      describe "and with buffered data" do
        let(:buffer_data) { "w00t" }
        let(:faye_client) do
          double('Faye::Client', publish: double('publication', callback: nil, errback: nil))
        end
        before do
          $redis.set(buffer_key, buffer_data)
          subject.stub(:client).and_return(faye_client)
        end

        it "publishes to the personal channel" do
          faye_client.should_receive(:publish)
            .with(bayeux_personal_channel, buffer_data)
          subject.incoming(message, callback)
        end
      end

    end

    describe "without an API key" do
      it "passes the message" do
        callback_was_called = false
        callback = ->(message) { callback_was_called = true }
        subject.incoming(message, callback)
        expect(callback_was_called).to be_true
      end
    end

    describe "with invalid API key" do
      let(:api_key) { 'keyNOfoo' }
      before do
        message['ext'] = {
          'apiKey' => api_key
        }
      end

      it "passes the message" do
        callback_was_called = false
        callback = ->(message) { callback_was_called = true }
        subject.incoming(message, callback)
        expect(callback_was_called).to be_true
      end
    end

  end

  describe "for non-subscribe messages" do
    let(:message) do
      { 
        'channel' => '/anything-but-subscribe'
      }
    end

    it "passes the message" do
      callback_was_called = false
      callback = ->(message) { callback_was_called = true }
      subject.incoming(message, callback)
      expect(callback_was_called).to be_true
    end
  end

  describe "for personal messages" do
    let(:message) do
      { 
        'channel' => '/anything-but-subscribe'
      }
    end

    it "passes the message" do
      callback_was_called = false
      callback = ->(message) { callback_was_called = true }
      subject.incoming(message, callback)
      expect(callback_was_called).to be_true
    end
  end
end
