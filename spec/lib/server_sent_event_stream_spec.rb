require 'spec_helper'

describe ServerSentEventStream do
  let(:output) { double("IO", write: nil, close: nil) }

  describe "#initialize" do
    it "returns a new ServerSentEventStream" do
      input, output = IO.pipe
      expect(ServerSentEventStream.new(output)).to be_kind_of(ServerSentEventStream)
    end
    it "raises error without IO" do
      expect { ServerSentEventStream.new() }.to raise_error(ArgumentError)
    end
  end

  describe "with open IO" do
    subject { ServerSentEventStream.new(output) }

    describe "#write_and_close" do
      describe "when the client stays connected" do
        before(:each) do
          subject.write_and_close {|stream| stream.write( foo: "bar" ) }
        end
        it "outputs a JSON event" do
          expect(output).to have_received(:write).with(%{data: {"foo":"bar"}\n\n})
        end
        it "closes the output" do
          expect(output).to have_received(:close)
        end
      end
      describe "when the client closes the connection" do
        before(:each) do
          subject.write_and_close {|stream| raise IOError, "cannot write" }
        end
        it "closes the output" do
          expect(output).to have_received(:close)
        end
      end
    end

    describe "#write" do
      describe "for an object" do
        before(:each) { subject.write( foo: "bar" ) }
        it "outputs a JSON event" do
          expect(output).to have_received(:write).with(%{data: {"foo":"bar"}\n\n})
        end
      end
      describe "for an object and meta" do
        before(:each) { subject.write({ foo: "bar" }, { retry: 10000 }) }
        it "outputs the meta data and a JSON event" do
          expect(output).to have_received(:write).with(
            %{retry: 10000\n}
          )
          expect(output).to have_received(:write).with(
            %{data: {"foo":"bar"}\n\n}
          )
        end
      end
    end

    describe "#close" do
      before(:each) { subject.close }
      it "terminates" do
        expect(output).to have_received(:close)
      end
    end

  end

end
