require 'spec_helper'

describe IntakesController do

  describe "#subscribe" do
    it "subscribes to the channel" do
      Redis.any_instance.should_receive(:subscribe).with('dash-test:intake:substantial-sf')
      get :subscribe, id: "substantial-sf"
    end
    it "responds as a Server Sent Event stream" do
      Redis.any_instance.should_receive(:subscribe)
      get :subscribe, id: "dash-test:substantial-sf"
      expect(response.headers['Content-Type']).to match('text/event-stream')
    end
  end

end
