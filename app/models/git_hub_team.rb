class GitHubTeam
  include GitHub

  attr_accessor :client, :id

  # Instantiate a new GitHubTeam object
  #
  # id - The Integer GitHub id of the team on GitHub
  # access_token  - The String access_token provided by the User
  # client_id     - The String client_id for the application client
  # client_secret - The String for the application secret
  #
  # Examples
  #
  #   group_assignment_repo = Group_AssignmentRepo.first
  #   creator               = group_assignment_repo.creator
  #
  #   github_team = GitHubTeam.new(group_assignment_repo.group.github_team_id, creator.access_token)
  #   # => #<GitHubTeam:0x007f98945fbf70 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=1888482>
  def initialize(id, access_token, client_id = nil, client_secret = nil)
    @id     = id
    @client = Octokit::Client.new(access_token: access_token, client_id: client_id, client_secret: client_secret)
  end

  def add_team_membership(new_user_github_login)
    with_error_handling do
      @client.add_team_membership(@id, new_user_github_login)
    end
  end

  def remove_team_membership(user_github_login)
    with_error_handling do
      @client.remove_team_membership(@id, user_github_login)
    end
  end

  def add_team_repository(full_name)
    with_error_handling do
      unless @client.add_team_repository(@id, full_name)
        fail GitHub::Error, 'Could not add team to the GitHub repository'
      end
    end
  end

  def team(options = {})
    with_error_handling { @client.team(@id, options) }
  end

  def team_repository?(full_name)
    with_error_handling do
      @client.team_repository?(@id, full_name)
    end
  end
end
