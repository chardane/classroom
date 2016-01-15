module Builders
  class AssignmentRepoBuilder
    include Builders::Helpers::GitHubPlanBuilderHelper
    include Builders::Helpers::GitHubRepositoryBuilderHelper

    def initialize(assignment, invitee)
      @assignment = assignment
      @invitee    = invitee
    end

    # Public: Create a GitHub repository for the AssignmentRepo submission
    #
    # Examples
    #
    #   Builder::AssignmentRepoBuilder.new(assignment, invitee).build
    #   # =>
    #
    # Returns and AssignmentRepo or raises an error that it could not be created
    def build
      verify_organization_has_private_repos_available(github_organization) if @assignment.private?

      submission_repository = create_github_repository(@assignment, github_invitee, github_organization)

      add_user_as_collaborator_to_submission_repository(submission_repository, github_invitee)
      push_starter_code_to(assignment, submission_repository)

      AssignmentRepo.create!(assignment: @assignment, user: @invitee, github_repo_id: submission_repository.id)
    end

    # Public: Destroy the AssignmentRepo and the GitHub submission repository if
    # available
    #
    # assignment_repo - The AssignmentRepo or GroupAssignmentRepo being destroyed
    #
    # Examples
    #
    #   Builder::AssignmentRepoBuilder.destroy(assignment_repo)
    #   # => true
    #
    # Returns if the object was destroyed
    def self.destroy(assignment_repo)
      begin
        GitHubRepository.new(assignment_repo.github_repo_id, assignment_repo.creator.access_token).destroy

        if assignment_repo.responds_to?(:github_team_id)
          GitHubTeam.new(assignment_repo, assignment_repo.creator.access_token).destroy
        end

      rescue GitHub::Error
        logger.error("Failed to destroy GitHub repository #{assignment_repo.github_repo_id}")
      end

      assignment_repo.destroy
    end

    private

    # Private: A helper method that gives information about the
    # AssignmentRepo's invitee from GitHub
    #
    # Examples
    #
    #   github_invitee.login
    #   # => tarebyte
    #
    # Returns a GitHubUser
    def github_invitee
      @github_invitee ||= GitHubUser.new(@invitee.github_client, @invitee.uid)
    end

    # Private: A helper method that gives information about the
    # AssignmentRepo's organization from GitHub
    #
    # Examples
    #
    #   github_organization.login
    #   # => tarebyte
    #
    # Returns a GitHubOrganization
    def github_organization
      @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
    end

    # Private: A helper method that retrieves the Assignment's organization
    #
    # Examples
    #
    #   organization
    #   # => <Organization:0x007fa245591e80
    #      id: 1,
    #      github_id: 12439714,
    #      title: "tarebytetestorg",
    #      created_at: Thu, 07 Jan 2016 16:48:07 UTC +00:00,
    #      updated_at: Thu, 07 Jan 2016 16:48:07 UTC +00:00,
    #      deleted_at: nil,
    #      slug: "12439714-tarebytetestorg">
    #
    # Returns a GitHubOrganization
    def organization
      @organization ||= @assignment.organization
    end
  end
end
