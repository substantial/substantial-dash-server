require 'spec_helper'

describe DashboardsController do

  describe "#broadcast" do
    it "subscribes to the dashboard channel" do
      $redis.should_receive(:subscribe).with('dashboard:substantial-sf')
      get :broadcast, id: "substantial-sf"
    end
    it "responds as a Server Sent Event stream" do
      $redis.should_receive(:subscribe)
      get :broadcast, id: "substantial-sf"
      expect(response.headers['Content-Type']).to match('text/event-stream')
    end
  end

end
