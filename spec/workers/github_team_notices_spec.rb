require 'spec_helper'

describe GithubTeamNotices do
  subject { GithubTeamNotices.new }
  before do
    ENV.stub(:[]).and_call_original
    ENV.stub(:[]).with('INTAKE_GITHUB_ORG_SLUG').and_return('the-foobar')
    ENV.stub(:[]).with('INTAKE_GITHUB_TEAM_SLUG').and_return('awesome-team')

    subject.stub(:octokit) do
      stack = Faraday::RackBuilder.new do |builder|
        builder.adapter :test do |stub|
          stub.get('/orgs/the-foobar/teams') do
            [ 200, { 'Content-Type' => 'application/json; charset=utf-8' }, '[
              {
                "name": "Other Team",
                "id": 666,
                "slug": "other-team"
              },
              {
                "name": "Awesome Team",
                "id": 555,
                "slug": "awesome-team"
              }
            ]' ]
          end
          stub.get('/teams/555/repos') do
            [ 200, { 'Content-Type' => 'application/json; charset=utf-8' }, '[
              {
                "id": 17195702,
                "name": "the-foobar-client-app",
                "full_name": "the-foobar/the-foobar-client-app"
              },
              {
                "id": 17195686,
                "name": "the-foobar-server-app",
                "full_name": "the-foobar/the-foobar-server-app"
              }
            ]' ]
          end
          stub.get('/repos/the-foobar/the-foobar-client-app/pulls?state=open') do
            [ 200, { 'Content-Type' => 'application/json; charset=utf-8' }, '[
              {
                "id": 1,
                "number": 1,
                "title": "Increase awesomeness"
              }
            ]' ]
          end
          stub.get('/repos/the-foobar/the-foobar-server-app/pulls?state=open') do
            [ 200, { 'Content-Type' => 'application/json; charset=utf-8' }, '[
              {
                "id": 2,
                "number": 1,
                "title": "Pumup up awesomeness"
              }
            ]' ]
          end
        end
      end
      Octokit::Client.new(
        middleware: stack
      )
    end
  end

  describe "#initialize" do
    it "returns a new GithubTeamNotices" do
      expect(GithubTeamNotices.new).to be_kind_of(GithubTeamNotices)
    end
  end

  describe "#intake" do
    let(:returns) { subject.intake }

    it "returns the team notices" do
      expect(returns).to be_kind_of(Hash)
      expect(returns[:pull_requests]).to be_kind_of(Array)
    end
  end

  describe "#pull_requests" do
    let(:returns) { subject.pull_requests }

    it "returns the repositories' PRs" do
      expect(returns.size).to eq(2)
      expect(returns.first.respond_to?(:id)).to be_true
      expect(returns.first.respond_to?(:number)).to be_true
      expect(returns.first.respond_to?(:title)).to be_true
    end
  end

  describe "#repos" do
    let(:returns) { subject.repos }

    it "returns the team's repositories" do
      expect(returns.size).to eq(2)
      expect(returns.first.respond_to?(:id)).to be_true
      expect(returns.first.respond_to?(:name)).to be_true
      expect(returns.first.respond_to?(:full_name)).to be_true
    end
  end

  describe "#team" do
    let(:returns) { subject.team }

    it "returns the organization's team" do
      expect(returns.respond_to?(:id)).to be_true
      expect(returns.respond_to?(:name)).to be_true
      expect(returns.respond_to?(:slug)).to be_true
    end
  end

end
