require 'spec_helper'
require 'client_command'

describe ClientCommand do
  subject { ClientCommand.new }

  describe '#exec' do
    let(:command) { 'foobar' }

    it 'should publish the command' do
      Faye::Client.any_instance.should_receive(:publish)
        .with(subject.bayeux_channel, { command: command }.to_json).and_call_original
      ClientCommand.exec(command)
    end
  end
end
