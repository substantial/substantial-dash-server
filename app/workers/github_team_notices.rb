require 'data_intake'

class GithubTeamNotices < DataIntake

  recurrence { minutely(1) }

  def intake
    {
      pull_requests: pull_requests
    }
  end

  def pull_requests
    return @pull_requests if @pull_requests
    @pull_requests = []
    repos.each do |repo|
      repo_prs = octokit.pull_requests(repo.full_name, 'open')
      @pull_requests.concat(repo_prs)
    end
    @pull_requests
  end

  def issues
    return @issues if @issues
    @issues = []
    repos.each do |repo|
      repo_issues = octokit.list_issues(repo.full_name, state: 'open')
      @issues.concat(repo_issues)
    end
    @issues
  end

  def repos
    return @repos if @repos
    @repos = octokit.team_repos(team.id)
  end

  def team
    return @team if @team
    teams = octokit.org_teams(ENV['INTAKE_GITHUB_ORG_SLUG'])
    @team = teams.find {|t| t['slug'] == ENV['INTAKE_GITHUB_TEAM_SLUG'] }
    unless @team
      Rails.logger.error "#{self.class} could not find team in teams list: #{ENV['INTAKE_GITHUB_TEAM_SLUG'].inspect}"
      return
    end
    @team
  end

  # GitHub Hypermedia API client!
  #
  def octokit
    return @octokit if @octokit
    stack = Faraday::RackBuilder.new do |builder|
      #builder.response :logger
      builder.use Faraday::HttpCache, {
        #logger: Rails.logger,
        store: Rails.cache,
        shared_cache: false # cache even though "Cache-Control: Private" 
      }
      builder.use Octokit::Response::RaiseError
      builder.adapter Faraday.default_adapter
    end
    @octokit = Octokit::Client.new(
      middleware: stack,
      access_token: ENV['INTAKE_GITHUB_API_TOKEN']
    )
  end
end
