module Builders
  module Helpers
    module GitHubRepositoryBuilderHelper
      include GitHub

      # Public: Add a GitHubUser as a collaborator to a GitHubRepository on GitHub
      #
      # submission_repository - The GitHubRepository representation on GitHub
      # github_user - The GitHubUser being added as a collaborator to the submission_repository
      #
      # Examples
      #
      #   add_user_as_collaborator_to_submission_repository(submission_repository, github_user)
      #   # => true
      #
      # Returns True is the user was added as a collaborator otherwise False
      def add_user_as_collaborator_to_submission_repository(submission_repository, github_user)
        delete_github_repository_on_failure(submission_repository) do
          submission_repository.add_collaborator(github_user)
        end
      end

      def create_github_repository(assignment, github_user, github_organization)
        repo_name         = "#{assignment.slug}-#{github_user.login}"
        repo_description  = "#{repo_name} created by Classroom for GitHub"

        repository = github_organization.create_repository(repo_name,
                                                           private: assignment.private?,
                                                           description: repo_description)

        GitHubRepository.new(repository.id github_organization.client.access_token)
      end

      def delete_github_repository_on_failure(submission_repository)
        yield
      rescue GitHub::Error
        silently_destroy_github_repository(submission_repository)
        raise GitHub::Error, 'Assignment failed to be created'
      end

      def silently_destroy_github_repository(submission_repository)
        GitHubRepository.destroy(submission_repository)
        true # Destroy ActiveRecord object even if we fail to delete the repository
      end

      def push_starter_code_to(assignment, submission_repository)
        return true unless assignment.private?

        creator                 = GitHubUser.new(assignment.creator)
        starter_code_repository = GitHubRepository.new(assignment.starter_code_repo_id, creator)

        delete_github_repository_on_failure(submission_repository) do
          submission_repository.get_starter_code_from(starter_code_repository)
        end
      end
    end
  end
end
