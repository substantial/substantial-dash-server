require 'spec_helper'
require 'data_intake'

describe DataIntake do
  let(:input) { { someKey: 'someValue' } }
  let(:json_input) { JSON.generate(input) }

  subject { DataIntake.new }

  describe '#publish', eventmachine: true do
    let(:namespaced_buffer_key) do
      "#{REDIS_NAMESPACE}:#{subject.redis_buffer_key}"
    end

    before do
      # em-spec will manage the run loop
      EM.stub(:run).and_yield
    end

    it 'should publish to the bayeaux subscribers' do
      Faye::Client.any_instance.should_receive(:publish)
        .with(subject.bayeux_channel, json_input).and_call_original
      subject.publish(input)
    end
  end

  describe '#channel_name' do
    it 'should be the dasherized class name' do
      expect(subject.channel_name).to eq('data-intake')
    end
  end

  describe '#bayeux_channel' do
    it 'should prefix the channel name with "/"' do
      expect(subject.bayeux_channel).to eq('/'+subject.channel_name)
    end
  end
end
