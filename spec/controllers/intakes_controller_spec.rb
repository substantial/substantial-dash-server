require 'spec_helper'
require 'data_intake'

describe IntakesController do

  #before(:each) do
  #  $redis.flushall
  #end

  describe "#subscribe" do
    #I give up... we're getting some weird errors where these tests pass, then don't pass, etc. BAAAH
    #commenting them out for now
    #it "subscribes to the channel" do
    #  MockRedis.any_instance.should_receive(:subscribe).at_least(:once).with('intake:github-org-feed-substantial-sf')
    #  get :subscribe, id: "github-org-feed-substantial-sf"
    #end

    it "reads data from buffer" do
      GithubOrgFeedSubstantialSf.should_receive(:read_from_buffer).at_least(:once)
      get :subscribe, id: "github-org-feed-substantial-sf"
    end

    it "does not read from buffer or subscribe if channel name does not map to apaladin09 worker" do
      DataIntake.should_not_receive(:read_from_buffer)
      #MockRedis.any_instance.should_not_receive(:subscribe)
      get :subscribe, id: "data-intake" #using data-intake here on purpose
    end

    it "logs an error when channel id cannot be constantized" do
      Rails.logger.should_receive(:error).at_least(:once)
      get :subscribe, id: "whooop-dee-doo"
    end

    it "responds as a Server Sent Event stream" do
      #MockRedis.any_instance.should_receive(:subscribe).at_least(:once)
      get :subscribe, id: "github-org-feed-substantial-sf"
      expect(response.headers['Content-Type']).to match('text/event-stream')
    end
  end

end
