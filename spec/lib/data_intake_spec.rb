require 'spec_helper'
require 'data_intake'

describe DataIntake do
  let(:input) { { someKey: 'someValue' } }
  let(:json_input) { JSON.generate(input) }
  let(:redis_channel_key) {'dash-test:intake:data-intake' }
  let(:redis_buffer_key) { "#{redis_channel_key}:buffer" }

  subject { DataIntake.new }

  it { should respond_to(:save_to_buffer) }

  describe 'when publishing' do
    it 'should save to buffer' do
      Redis.any_instance.should_receive(:set).with(redis_buffer_key, json_input)
      subject.publish(input)
    end

    it 'should publish to redis' do
      Redis.any_instance.should_receive(:publish).with(redis_channel_key, json_input)
      subject.publish(input)
    end
  end
end
