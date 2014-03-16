require 'spec_helper'
require 'subscriber_auth'

describe SubscriberAuth do
  subject { SubscriberAuth.new }

  describe "for subscribe messages" do
    let(:message) do
      { 
        'channel' => '/meta/subscribe',
        'subscription' => 'awesomeness'
      }
    end

    describe "with valid API key" do
      let(:api_key) { 'keyfoo' }
      before do
        message['ext'] = {
          'apiKey' => api_key
        }
        $redis.mapped_hmset(api_key, {
          'uid' => '55555',
          'info' => {
            'name' => 'Foo Barsmith'
          }
        })
      end

      it "passes the message" do
        callback_was_called = false
        callback = ->(message) { callback_was_called = true }
        subject.incoming(message, callback)
        expect(callback_was_called).to be_true
      end
    end

    describe "without an API key" do
      it "calls back with an error" do
        callback_message = nil
        callback = ->(message) { callback_message = message }
        subject.incoming(message, callback)
        expect(callback_message['error']).to eq('API key is required')
      end
    end

    describe "with invalid API key" do
      let(:api_key) { 'keyNOfoo' }
      before do
        message['ext'] = {
          'apiKey' => api_key
        }
      end

      it "calls back with an error" do
        callback_message = nil
        callback = ->(message) { callback_message = message }
        subject.incoming(message, callback)
        expect(callback_message['error']).to eq('Unauthorized')
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
end
