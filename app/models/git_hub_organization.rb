class GitHubOrganization
  include GitHub

  attr_accessor :client, :id

  # Instantiate a new GitHubOrganization object
  #
  # id            - The Integer GitHub id of the Organization
  # access_token  - The String access_token provided by the Organization (see Organization#access_token)
  # client_id     - The String client_id for the application client
  # client_secret - The String for the application secret
  #
  # Example
  #
  #   organization        = Organization.first
  #   github_organization = GitHubOrganization.first(organization.github_id, organization.access_token)
  #   # => #<GitHubOrganization:0x007f37203fbf93 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=6667880>
  #
  #   github_organization = GitHubOrganization.new(organization.github_id,
  #                                                nil,
  #                                                '6fabe6575fee7f6a975c',
  #                                                '1914c23b3714b821a3e34663f94f9041cb141e97')
  #   # => #<GitHubOrganization:0x007f37203fbf93 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=6667880>
  def initialize(id, access_token, client_id = nil, client_secret = nil)
    @id     = id
    @client = Octokit::Client.new(access_token: access_token, client_id: client_id, client_secret: client_secret)
  end

  # Public: Add a GitHubUser as a member of the GitHubOrganization on GitHub
  #
  # github_user - The GitHubUser that is being added to the org
  #
  # Examples
  #
  #   github_organization.add_membership(github_user)
  #   # => { "url": "https://api.github.com/orgs/invitocat/memberships/defunkt",
  #      "state": "pending",
  #      "role": "admin",
  #      "organization_url": "https://api.github.com/orgs/invitocat",
  #      ...
  #      }
  #
  # Returns a Sawyer::Resource Hash representing the users membership
  def add_membership(github_user)
    with_error_handling do
      if organization_member?(github_user.login)
        @client.organization_membership(github_user.login)
      else
        @client.update_organization_membership(github_user.login, user: github_user.login)
      end
    end
  end

  # Public: Find out whether the user in question is an active admin of the
  # GitHubOrganization on GitHub
  #
  # github_user - The GitHubUser that is trying to be identified as an active admin
  #
  # Examples
  #
  #   github_organization.active_admin?(github_user)
  #   # => true
  #
  #   github_organization.active_admin?(github_user)
  #   # => false
  #
  # Returns True is the GitHubUser is an active admin, False otherwise
  def active_admin?(github_user)
    with_error_handling do
      membership = @client.organization_membership(login, user: github_user.login)
      membership.role == 'admin' && membership.state == 'active'
    end
  end

  # Public: Accept a membership invitation for a GitHub Organization
  #
  # name - The String that you want the repository to be called on GitHub
  # user_repo_options - The Hash of other options that you want to pass (example private: true)
  #
  # Examples
  #
  #   github_organization.create_repository('foobar')
  #   # => #<GitHubRepository:0x007f98945fbf70 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=35079964>
  #
  # Returns a GitHubRepository object
  def create_repository(name, users_repo_options = {})
    repo_options = github_repo_default_options.merge(users_repo_options)

    repo = with_error_handling do
      @client.create_repository(name, repo_options)
    end

    GitHubRepository.new(repo.id, @client.access_token, @client.client_id, @client.client_secret)
  end

  # Public: Create a new team for the GitHubOrganization on GitHub
  #
  # name - The String that you want the team to be called on GitHub
  #
  # Examples
  #
  #   github_organization.create_team('The A Team')
  #   # => #<GitHubTeam:0x007f98945fbf70 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=1888482>
  #
  # Returns a GitHubTeam object
  def create_team(name)
    github_team = with_error_handling do
      @client.create_team(@id,
                          description: "#{name} created by Classroom for GitHub",
                          name: team_name,
                          permission: 'push')
    end

    GitHubTeam.new(github_team.id, @client.access_token, @client.client_id, @client.client_secret)
  end

  # Public: Accept a membership invitation for a GitHub Organization
  #
  # options = A Hash of options for the request
  #
  # Examples
  #
  #  github_organization.organization_members
  #  # => [{:login=>"tarebyte",
  #     :id=>564113,
  #     ...
  #     }]
  #
  # Returns an Array of members
  def organization_members(options = {})
    with_error_handling { @client.organization_members(@id, options) }
  end

  # Public: Check to see if a GitHubUser is a member of a GitHubOrganization on GitHub
  #
  # github_user - The GitHubUser whose membership being checked
  #
  # Examples
  #
  #   github_organization.organization_member?(github_user)
  #   # => true
  #
  # Returns a boolean of whether or not the GitHub is a member
  def organization_member?(github_user)
    with_error_handling { @client.organization_member?(@id, github_user.login) }
  end

  # Public: Return the GitHubOrganizations private repository plan on GitHub
  #
  # Examples
  #
  #   github_organization.plan
  #   # => { owned_private_repos: 2, private_repos: 10 }
  #
  # Returns a Hash with the GitHubOrganization owned_private_repos and private_repos
  def plan
    with_error_handling do
      organization = @client.organization(@id, headers: no_cache_headers)

      if organization.owned_private_repos.present? && organization.plan.present?
        { owned_private_repos: organization.owned_private_repos, private_repos: organization.plan.private_repos }
      else
        fail GitHub::Error, 'Cannot retrieve this organizations repo plan, please reauthenticate your token.'
      end
    end
  end

  # Public: Remove a GitHubUser from the GitHubOrganization on GitHub
  #
  # If the GitHubUser is an active admin of the organization on GitHub they
  # will not be removed
  #
  # github_user - The GitHubUser that is being removed
  #
  # Examples
  #
  #   github_organization.remove_organization_member(admin_github_user)
  #   # => false
  #
  #   github_organization.remove_organization_member(github_user)
  #   # => true
  #
  # Returns the boolean status of the members removal
  def remove_organization_member(github_user)
    begin
      return false if active_admin?(github_user.login)
    rescue GitHub::NotFound
      return false
    end

    with_error_handling do
      @client.remove_organization_member(@id, github_user.login)
    end
  end

  # Public: Route any missing errors for GitHubOrganization to
  # Octokit's Sawyer::Resource result from the GitHub API
  #
  # method_name - the method which you are trying to call
  # arguments   - the arguments that you need to pass
  # block       - (unused) if you are passing a block
  #
  # Examples
  #   organization         = Organization.find(1)
  #   github_organization  = GitHubOrganization.new(organization.github_id, organization.access_token)
  #
  #   github_organization.login
  #   # => "tatooine-moisture-farmers"
  #
  #   github_organization.html_url
  #   # => "https://github.com/tatooine-moisture-farmers"
  #
  #   github_organization.foobar
  #   # => NoMethodError: undefined foobar for GitHubOrganization
  #
  # Returns the result from the method or raises method missing
  def method_missing(method_name, *arguments, &_block)
    with_error_handling do
      result = @client.organization(@id, arguments)[method_name.to_sym]
      return result if result.present?

      fail NoMethodError, "undefined #{method_name} for #{self.class}"
    end
  end

  # Public: Include the additional methods available from the Octokit
  # Sawyer::Resource to .respond_to?
  #
  # Examples
  #   organization         = Organization.find(1)
  #   github_organization  = GitHubOrganization.new(organization)
  #
  #   github_organization.login
  #   # => true
  #
  #   github_organization.foobar
  #   # => false
  #
  # Returns true if the object responds to the method, False otherwise
  def respond_to_missing?(method_name, include_private = false)
    @client.organization(@id)[method_name.to_sym] || super
  end

  private

  # Internal: A set of default options for newly created GitHub repositories
  # see (GitHubOrganization#create_repository)
  #
  # Examples
  #
  #   github_repo_default_options
  #   # => { has_issues: true, has_wiki: true, has_downloads: true, organization: 1 }
  #
  # Returns the hash of options for the organization repo
  def github_repo_default_options
    {
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true,
      organization:  @id
    }
  end
end
