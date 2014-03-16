require 'spec_helper'
require 'publisher_auth'

describe PublisherAuth do
  subject { PublisherAuth.new }
  let(:api_key) { '55555' }
  before { ENV.stub(:[]).with('BAYEUX_PUBLISH_KEY').and_return(api_key) }

  describe "for event messages" do
    let(:message) do
      { 
        'channel' => '/awesomeness',
        'data' => '{ "foo": "bar" }'
      }
    end

    describe "with valid API key" do
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

      it "keeps the API key secret" do
        callback_message = nil
        callback = ->(message) { callback_message = message }
        subject.incoming(message, callback)
        expect(callback_message['ext']).to be_kind_of(Hash)
        expect(callback_message['ext']['apiKey']).to be_nil
      end
    end

    describe "with invalid API key" do
      before do
        message['ext'] = {
          'apiKey' => 'not-the-correct-key'
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

  describe "for meta messages" do
    let(:message) do
      { 
        'channel' => '/meta/anything'
      }
    end

    it "passes the message" do
      callback_was_called = false
      callback = ->(message) { callback_was_called = true }
      subject.incoming(message, callback)
      expect(callback_was_called).to be_true
    end
  end

  describe PublisherAuth::Client do
    subject { PublisherAuth::Client.new }
    let(:message) do
      { 
        'channel' => '/awesomeness',
        'data' => '{ "foo": "bar" }'
      }
    end
    before do
      message['ext'] = {
        'apiKey' => api_key
      }
    end

    it "passes the API key" do
      callback_message = nil
      callback = ->(message) { callback_message = message }
      subject.outgoing(message, callback)
      expect(callback_message['ext']).to be_kind_of(Hash)
      expect(callback_message['ext']['apiKey']).to eq(api_key)
    end
  end
end
