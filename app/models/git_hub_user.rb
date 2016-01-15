class GitHubUser
  include GitHub

  attr_reader :client, :id

  # Instantiate a new GitHubUser object
  #
  # id - The Integer GitHub id of the User
  # access_token  - The String access_token provided by the User
  # client_id     - The String client_id for the application client
  # client_secret - The String for the application secret
  #
  # Examples
  #
  #   user = User.first
  #   github_user = GitHubUser.new(user.uid, user.access_token)
  #   # => #<GitHubUser:0x007f98945fbf70 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=564113>
  #
  #   github_user = GitHubUser.new(user.uid,
  #                                nil,
  #                                '6fabe6575fee7f6a975c',
  #                                '1914c23b3714b821a3e34663f94f9041cb141e97')
  #   # => #<GitHubUser:0x007f18445fbf70 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=564113>
  def initialize(id, access_token, client_id = nil, client_secret = nil)
    @id     = id
    @client = Octokit::Client.new(access_token: access_token, client_id: client_id, client_secret: client_secret)
  end

  # Public: Accept a membership invitation for a GitHub Organization
  # If the GitHubUser is already a member it will return the membership
  #
  # github_organization - The GitHubOrganization that the membership was extended from
  #
  # Examples
  #
  #   github_organization.accept_membership(github_user)
  #   # => { "url": "https://api.github.com/orgs/octocat/memberships/defunkt",
  #          "state": "active",
  #          "role": "admin",
  #          ...
  #        }
  #
  # Returns a Sawyer::Resource Hash representing the organization membership
  def accept_organiation_membership(github_organization)
    with_error_handling do
      if github_organization.organization_member?(login)
        @client.organization_membership(github_organization.login)
      else
        @client.update_organization_membership(github_user.login, state: 'active')
      end
    end
  end

  # Public: List the users organization memberships where the user is active
  #
  # Examples
  #
  #   github_user.active_organization_memberships
  #   # => [{:url=>"https://api.github.com/orgs/github-beta/memberships/tarebyte",
  #      :state=>"active",
  #      :role=>"member",
  #      ...
  #      }]
  #
  # Returns an array of Sawyer::Resource Hashes of active organiation memberships
  def active_organization_memberships
    with_error_handling do
      @client.organization_memberships(state: 'active', headers: no_cache_headers)
    end
  end

  # Public: List the GitHubUsers GitHub organization memberships where the user is active
  #
  # Examples
  #
  #   github_user.authorized_access_token?
  #   # => true
  #
  # Returns a True if the access_token is authorized, False otherwise
  def authorized_access_token?
    with_error_handling do
      application_github_client.check_application_authorization(@client.access_token,
                                                                headers: no_cache_headers).present?
    end
  rescue GitHub::NotFound
    false
  end

  # Public: List the users access_token permission scopes
  #
  # Examples
  #
  #   github_user.client_scopes
  #   # => ["admin:org", "delete_repo", "repo", "user:email"]
  #
  # Returns an array of the strings with the permission scopes
  def client_scopes
    with_error_handling { @client.scopes(@client.access_token, headers: no_cache_headers) }
  rescue GitHub::Forbidden
    []
  end

  # Public: Route any missing errors for GitHubUser to
  # Octokit's Sawyer::Resource result from the GitHub API
  #
  # method_name - the method which you are trying to call
  # arguments   - the arguments that you need to pass
  # block       - (unused) if you are passing a block
  #
  # Examples
  #
  #   github_user.login
  #   # => "tarebyte"
  #
  #   github_user.foobar
  #   # => NoMethodError: undefined foobar for GitHubUser
  #
  # Returns the result from the method or raises method missing
  def method_missing(method_name, *arguments, &_block)
    with_error_handling do
      result = @client.user(@id, arguments)[method_name.to_sym]
      return result if result.present?

      fail NoMethodError, "undefined #{method_name} for #{self.class}"
    end
  end

  # Public: Include the additional methods available from the Octokit
  # Sawyer::Resource to .respond_to?
  #
  # method_name     - the method which you are trying to call
  # include_private - The Boolean if you want to include private methods
  #
  # Examples
  #
  #   github_user.responds_to?(:login)
  #   # => true
  #
  #   github_user.responds_to?(:foobar)
  #   # => false
  #
  # Returns True if the object responds to the method False otherwise
  def respond_to_missing?(method_name, include_private = false)
    @client.user(@id)[method_name.to_sym] || super
  end
end
