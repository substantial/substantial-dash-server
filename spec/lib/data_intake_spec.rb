require 'spec_helper'
require 'data_intake'

describe DataIntake do
  subject { DataIntake.new }

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
