class GitHubRepository
  include GitHub

  attr_accessor :client, :id

  # Instantiate a new GitHubUser object
  #
  # id - The Integer GitHub id of the User
  # access_token  - The String access_token provided by the User
  # client_id     - The String client_id for the application client
  # client_secret - The String for the application secret
  #
  # Examples
  #
  #   assignment_repo   = AssignmentRepo.first
  #   github_repository = GitHubRepository.new(assignment_repo.github_repo_id, assignment_repo.creator.access_token)
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

  # Public: Add a GitHubUser as a collaborator to the GitHubRepository on GitHub
  #
  # collaborator - The GitHubUser being added
  #
  # Examples
  #
  #   github_user = GitHubUser.new(User.last.uid, User.last.access_token)
  #   github_repository.add_collaborator(github_user)
  #   # => true
  #
  # Returns a True if the collaborator was added, false otherwise
  def add_collaborator(collaborator)
    with_error_handling do
      @client.add_collaborator(@id, collaborator.login)
    end
  end

  # Public: Push starter code from one GitHub repostory to another
  #
  # repo - The GitHubRepository that the code is being retrieved from
  # assignment_creator - The GitHubUser who created the assignment
  #
  # Examples
  #
  #   assignment      = Assignment.first
  #   assignment_repo = assignment.assignment_repos.first
  #   creator         = GitHubUser.new(assignment.creator.uid, assignment.creator.access_token)
  #
  #   source_repo     = GitHubRepository.new(assignment.starter_code_repo_id, creator)
  #   submission_repo = GitHubRepository.new(assignment_repo.github_repo_id, creator.client.access_token)
  #
  #   submission_repo.get_starter_code_from(source_repo, creator)
  #   # =>
  #
  # Returns
  def get_starter_code_from(repo, assignment_creator)
    with_error_handling do
      @client.put(
        "/repositories/#{@id}/import",
        headers: import_preview_header,
        'vcs': 'git',
        'vcs_url': "https://github.com/#{repo.full_name}",
        'vcs_username': assignment_creator.login,
        'vcs_password': assignment_creator.client.access_token
      )
    end
  end

  # Public: Destroy a GitHubRepository on GitHub
  #
  # repository - The GitHubRepository that is being destroyed
  #
  # Examples
  #
  #   destroy(submission_repository)
  #   # => true
  #
  # Returns True if the repository was destroyed, otherwise false
  def destroy(repository)
    with_error_handling do
      repository.client.delete_repository(repository.id)
    end
  end

  # Public: Return the GitHubRepositories GitHubOrganization
  #
  # Examples
  #
  #   github_repository.organization
  #   # => #<GitHubOrganization:0x007f37203fbf93 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=6667880>
  #
  # Returns a GitHubOrganization object
  def organization
    with_error_handling do
      organization = @client.repository(@id).organization
      GitHubOrganization.new(organization.id, @client.access_token)
    end
  end

  # Public: Route any missing errors for GitHubRepository to
  # Octokit's Sawyer::Resource result from the GitHub API
  #
  # method_name - the method which you are trying to call
  # arguments   - the arguments that you need to pass
  # block       - (unused) if you are passing a block
  #
  # Examples
  #   assignment_repo   = AssignmentRepo.first
  #   github_repository = GitHubRepository.new(assignment_repo.github_repo_id, assignment_repo.creator.access_token)
  #
  #   github_repository.full_name
  #   # => "tatooine-moisture-farmers/rails"
  #
  #   github_repository.foobar
  #   # => NoMethodError: undefined foobar for GitHubRepository
  #
  # Returns the result from the method or raises method missing
  def method_missing(method_name, *arguments, &_block)
    with_error_handling do
      result = @client.repository(@id, arguments)[method_name.to_sym]
      return result if result.present?

      fail NoMethodError, "undefined #{method_name} for #{self.class}"
    end
  end

  # Public: Include the additional methods available from the Octokit
  # Sawyer::Resource to .respond_to?
  #
  # Examples
  #
  #   assignment_repo   = AssignmentRepo.first
  #   github_repository = GitHubRepository.new(assignment_repo.github_repo_id, assignment_repo.creator.access_token)
  #
  #   github_repository.responds_to?(:full_name)
  #   # => true
  #
  #   github_repository.responds_to?(:foobar)
  #   # => false
  #
  # Returns True if the object responds to the method False otherwise
  def respond_to_missing?(method_name, include_private = false)
    @client.repository(@id)[method_name.to_sym] || super
  end
end
