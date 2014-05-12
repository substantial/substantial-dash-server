require 'spec_helper'
require 'data_intake'

describe FayePublisher do
  let(:input) { { someKey: 'someValue' } }
  let(:json_input) { JSON.generate(input) }

  subject { FayePublisher.new }

  describe '#publish', eventmachine: true do
    before do
      # em-spec will manage the run loop
      EM.stub(:run).and_yield

      subject.define_singleton_method(:bayeux_channel) do
        '/foo-channel'
      end
    end

    it 'should publish to the bayeaux subscribers' do
      Faye::Client.any_instance.should_receive(:publish)
        .with('/foo-channel', json_input).and_call_original
      subject.publish(input)
    end
  end

  describe '#bayeux_channel' do
    it 'should raise not implemented' do
      expect { subject.bayeux_channel }.to raise_error(NotImplementedError)
    end
  end
end
